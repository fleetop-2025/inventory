import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddInventoryPage extends StatefulWidget {
  const AddInventoryPage({super.key});

  @override
  State<AddInventoryPage> createState() => _AddInventoryPageState();
}

class _AddInventoryPageState extends State<AddInventoryPage> {
  String? _selectedProductId;
  Map<String, dynamic>? _selectedProductData;
  final TextEditingController _quantityController = TextEditingController();
  List<Map<String, dynamic>> _productList = [];

  bool _isWorking = false;
  bool _isFaulty = false;

  Future<void> _fetchProducts() async {
    final snapshot = await FirebaseFirestore.instance.collection('products').get();
    setState(() {
      _productList = snapshot.docs.map((doc) {
        final data = doc.data();
        data['productId'] = doc.id;
        return data;
      }).toList();
    });
  }

  void _submitRequest() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final uid = currentUser?.uid;

    if (_selectedProductData != null &&
        _quantityController.text.trim().isNotEmpty &&
        uid != null &&
        (_isWorking ^ _isFaulty)) {
      final quantity = int.tryParse(_quantityController.text.trim());

      if (quantity == null || quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid quantity")),
        );
        return;
      }

      final data = {
        'productName': _selectedProductData!['productName'],
        'productId': _selectedProductData!['productId'],
        'category': _selectedProductData!['category'],
        'price': _selectedProductData!['price'],
        'quantity': quantity,
        'requestedBy': uid,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (_isWorking) {
        await FirebaseFirestore.instance.collection('TemporaryInventoryAdd').add(data);
      } else if (_isFaulty) {
        await FirebaseFirestore.instance.collection('TemporaryInTransitOut').add(data);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request submitted for admin approval")),
      );

      setState(() {
        _selectedProductId = null;
        _selectedProductData = null;
        _quantityController.clear();
        _isWorking = false;
        _isFaulty = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields and select exactly one condition")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Inventory")),
      body: _productList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Request New Product Addition",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedProductId,
                  items: _productList.map((product) {
                    return DropdownMenuItem<String>(
                      value: product['productId'],
                      child: Text(product['productName'] ?? 'Unknown'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProductId = value;
                      _selectedProductData = _productList.firstWhere(
                            (product) => product['productId'] == value,
                      );
                    });
                  },
                  decoration: const InputDecoration(labelText: "Select Product"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _quantityController,
                  decoration: const InputDecoration(labelText: "Quantity"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  title: const Text("Working"),
                  value: _isWorking,
                  onChanged: (value) {
                    setState(() {
                      _isWorking = value!;
                      if (_isWorking) _isFaulty = false;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text("Faulty"),
                  value: _isFaulty,
                  onChanged: (value) {
                    setState(() {
                      _isFaulty = value!;
                      if (_isFaulty) _isWorking = false;
                    });
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitRequest,
                  child: const Text("Submit Request"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
