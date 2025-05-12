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

  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('categories').get();
      final List<String> fetchedCategories =
      snapshot.docs.map((doc) => doc['name'] as String).toList();

      setState(() {
        _categories = fetchedCategories;
        _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $e')),
      );
    }
  }

  Future<bool> _checkDuplicate(String name, String id) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('productName', isEqualTo: name)
        .get();

    final idSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('productId', isEqualTo: id)
        .get();

    return querySnapshot.docs.isNotEmpty || idSnapshot.docs.isNotEmpty;
  }

  Future<void> _registerProduct() async {
    final name = _nameController.text.trim();
    final id = _idController.text.trim();
    final priceText = _priceController.text.trim();
    final description = _descriptionController.text.trim();

    try {
      final duplicateExists = await _checkDuplicate(name, id);

      if (duplicateExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product with same name or ID already exists.')),
        );
        return;
      }

      final price = double.tryParse(priceText);
      if (price == null || price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid price greater than 0.')),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('products').add({
        'productName': name,
        'productId': id,
        'category': _selectedCategory,
        'price': price,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product registered successfully!')),
      );

      _formKey.currentState?.reset();
      _nameController.clear();
      _idController.clear();
      _priceController.clear();
      _descriptionController.clear();

      setState(() {
        _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
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
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _isLoadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : _categories.isEmpty
                  ? const Center(child: Text("No categories available."))
                  : Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: "Product Name"),
                      validator: (val) =>
                      val == null || val.trim().isEmpty ? "Enter product name" : null,
                    ),
                    TextFormField(
                      controller: _idController,
                      decoration: const InputDecoration(labelText: "Product ID"),
                      validator: (val) =>
                      val == null || val.trim().isEmpty ? "Enter product ID" : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(labelText: "Category"),
                      items: _categories
                          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedCategory = value),
                      validator: (val) => val == null ? 'Select a category' : null,
                    ),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: "Price"),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return "Enter price";
                        }
                        final num? price = num.tryParse(val.trim());
                        if (price == null || price <= 0) {
                          return "Enter a valid positive price";
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: "Description"),
                      maxLines: 3,
                      validator: (val) =>
                      val == null || val.trim().isEmpty ? "Enter description" : null,
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
          ),
        ),
      ),
    );
  }
}
