import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductRegistrationPage extends StatefulWidget {
  const ProductRegistrationPage({super.key});

  @override
  State<ProductRegistrationPage> createState() => _ProductRegistrationPageState();
}

class _ProductRegistrationPageState extends State<ProductRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'GPS';

  Future<void> _registerProduct() async {
    try {
      await FirebaseFirestore.instance.collection('products').add({
        'productName': _nameController.text.trim(),
        'productId': _idController.text.trim(),
        'category': _selectedCategory,
        'price': double.parse(_priceController.text.trim()),
        'description': _descriptionController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product registered successfully!')),
      );

      _formKey.currentState?.reset();
      setState(() {
        _selectedCategory = 'GPS';
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Product Registration")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Product Name"),
                validator: (val) => val!.isEmpty ? "Enter product name" : null,
              ),
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(labelText: "Product ID"),
                validator: (val) => val!.isEmpty ? "Enter product ID" : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: "Category"),
                items: const [
                  DropdownMenuItem(value: 'GPS', child: Text('GPS')),
                  DropdownMenuItem(value: 'Relays', child: Text('Relays')),
                  DropdownMenuItem(value: 'Sensors', child: Text('Sensors')),
                ],
                onChanged: (value) => setState(() => _selectedCategory = value!),
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: "Price"),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? "Enter price" : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
                validator: (val) => val!.isEmpty ? "Enter description" : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _registerProduct();
                  }
                },
                child: const Text("Register Product"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
