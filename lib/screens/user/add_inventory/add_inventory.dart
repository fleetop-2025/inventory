import 'package:flutter/material.dart';

class AddInventoryPage extends StatefulWidget {
  const AddInventoryPage({super.key});

  @override
  State<AddInventoryPage> createState() => _AddInventoryPageState();
}

class _AddInventoryPageState extends State<AddInventoryPage> {
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  void _submitRequest() {
    String name = _productNameController.text.trim();
    String qty = _quantityController.text.trim();

    if (name.isNotEmpty && qty.isNotEmpty) {
      // Firebase logic goes here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request submitted for admin approval")),
      );

      _productNameController.clear();
      _quantityController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text("Request New Product Addition", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: _productNameController,
            decoration: const InputDecoration(labelText: "Product Name"),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _quantityController,
            decoration: const InputDecoration(labelText: "Quantity"),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitRequest,
            child: const Text("Submit Request"),
          ),
        ],
      ),
    );
  }
}
