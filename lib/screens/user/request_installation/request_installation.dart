import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RequestInstallationPage extends StatefulWidget {
  const RequestInstallationPage({super.key});

  @override
  State<RequestInstallationPage> createState() => _RequestInstallationPageState();
}

class _RequestInstallationPageState extends State<RequestInstallationPage> {
  String? _selectedProductId;
  List<Map<String, dynamic>> _inventoryItems = [];

  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _imeiController = TextEditingController();
  final TextEditingController _simController = TextEditingController();
  final TextEditingController _vehicleController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();

  Future<void> _fetchInventoryItems() async {
    final snapshot = await FirebaseFirestore.instance.collection('inventory').get();
    setState(() {
      _inventoryItems = snapshot.docs.map((doc) {
        final data = doc.data();
        data['productId'] = doc.id;
        return data;
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchInventoryItems();
  }

  void _submitInstallation() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final uid = currentUser?.uid;

    String location = _locationController.text.trim();
    String phone = _phoneController.text.trim();
    int? quantity = int.tryParse(_quantityController.text.trim());
    String imei = _imeiController.text.trim();
    String sim = _simController.text.trim();
    String vehicle = _vehicleController.text.trim();
    String company = _companyController.text.trim();

    final selectedItem = _inventoryItems.firstWhere(
          (item) => item['productId'] == _selectedProductId,
      orElse: () => {},
    );

    if (selectedItem.isNotEmpty &&
        location.isNotEmpty &&
        phone.isNotEmpty &&
        quantity != null &&
        quantity > 0 &&
        imei.isNotEmpty &&
        sim.isNotEmpty &&
        vehicle.isNotEmpty &&
        company.isNotEmpty &&
        uid != null) {

      await FirebaseFirestore.instance.collection('TemporaryInstallation').add({
        'productName': selectedItem['productName'],
        'productId': selectedItem['productId'],
        'quantity': quantity,
        'location': location,
        'phone': phone,
        'imeiNumber': imei,
        'simNumber': sim,
        'vehicleNumber': vehicle,
        'companyName': company,
        'requestedBy': uid,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Installation request sent for admin approval")),
      );

      setState(() {
        _selectedProductId = null;
        _locationController.clear();
        _quantityController.clear();
        _phoneController.clear();
        _imeiController.clear();
        _simController.clear();
        _vehicleController.clear();
        _companyController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields with valid values.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _inventoryItems.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Request Installation", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedProductId,
              items: _inventoryItems.map((item) {
                return DropdownMenuItem<String>(
                  value: item['productId'],
                  child: Text(item['productName'] ?? 'Unknown'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProductId = value;
                });
              },
              decoration: const InputDecoration(labelText: "Select Product from Inventory"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: "Quantity to Install"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: "Installation Location"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: "Phone Number"),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _imeiController,
              decoration: const InputDecoration(labelText: "IMEI Number"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _simController,
              decoration: const InputDecoration(labelText: "SIM Number"),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _vehicleController,
              decoration: const InputDecoration(labelText: "Vehicle Number"),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _companyController,
              decoration: const InputDecoration(labelText: "Company Name"),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitInstallation,
              child: const Text("Send Request"),
            ),
          ],
        ),
      ),
    );
  }
}
