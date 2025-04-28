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
  final TextEditingController _totalQuantityController = TextEditingController();
  final TextEditingController _workingQuantityController = TextEditingController();
  final TextEditingController _faultyQuantityController = TextEditingController();

  List<Map<String, dynamic>> _productList = [];

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
        _totalQuantityController.text.trim().isNotEmpty &&
        _workingQuantityController.text.trim().isNotEmpty &&
        _faultyQuantityController.text.trim().isNotEmpty &&
        uid != null) {

      final totalQuantity = int.tryParse(_totalQuantityController.text.trim());
      final workingQuantity = int.tryParse(_workingQuantityController.text.trim());
      final faultyQuantity = int.tryParse(_faultyQuantityController.text.trim());

      if (totalQuantity == null || workingQuantity == null || faultyQuantity == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter valid numeric quantities")),
        );
        return;
      }

      if ((workingQuantity + faultyQuantity) != totalQuantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Working + Faulty must equal Total Quantity")),
        );
        return;
      }

      // If workingQuantity > 0, create request in TemporaryInventoryAdd
      if (workingQuantity > 0) {
        await FirebaseFirestore.instance.collection('TemporaryInventoryAdd').add({
          'productName': _selectedProductData!['productName'],
          'productId': _selectedProductData!['productId'],
          'category': _selectedProductData!['category'],
          'price': _selectedProductData!['price'],
          'quantity': workingQuantity,
          'requestedBy': uid,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // If faultyQuantity > 0, create request in TemporaryInTransitOut
      if (faultyQuantity > 0) {
        await FirebaseFirestore.instance.collection('TemporaryInTransitOut').add({
          'productName': _selectedProductData!['productName'],
          'productId': _selectedProductData!['productId'],
          'category': _selectedProductData!['category'],
          'price': _selectedProductData!['price'],
          'quantity': faultyQuantity,
          'requestedBy': uid,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request(s) submitted for admin approval")),
      );

      setState(() {
        _selectedProductId = null;
        _selectedProductData = null;
        _totalQuantityController.clear();
        _workingQuantityController.clear();
        _faultyQuantityController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields")),
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
    return _productList.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              "Request New Product Addition",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              controller: _totalQuantityController,
              decoration: const InputDecoration(labelText: "Total Quantity"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _workingQuantityController,
              decoration: const InputDecoration(labelText: "Working Quantity"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _faultyQuantityController,
              decoration: const InputDecoration(labelText: "Faulty Quantity"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitRequest,
              child: const Text("Submit Request"),
            ),
          ],
        ),
      ),
    );
  }
}
