import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InstallationTypePage extends StatefulWidget {
  const InstallationTypePage({super.key});

  @override
  State<InstallationTypePage> createState() => _InstallationTypePageState();
}

class _InstallationTypePageState extends State<InstallationTypePage> {
  final _nameController = TextEditingController();

  Map<String, Map<String, String>> _categoryProductMap = {}; // category -> {productId: productName}
  Set<String> _selectedProductIds = {};
  Set<String> _selectedProductNames = {};

  @override
  void initState() {
    super.initState();
    _loadAllProducts();
  }

  /// Load all products grouped by their category
  Future<void> _loadAllProducts() async {
    final snapshot = await FirebaseFirestore.instance.collection('products').get();

    Map<String, Map<String, String>> categoryMap = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final category = data['category'] ?? 'Uncategorized';
      final productName = data['productName'] ?? 'Unnamed';

      if (!categoryMap.containsKey(category)) {
        categoryMap[category] = {};
      }
      categoryMap[category]![doc.id] = productName;
    }

    setState(() {
      _categoryProductMap = categoryMap;
    });
  }

  Future<bool> _isDuplicateName(String name) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('installation_types')
        .where('name', isEqualTo: name)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> _createType() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedProductIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name and select at least one product.')),
      );
      return;
    }

    final isDuplicate = await _isDuplicateName(name);
    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An installation type with this name already exists.')),
      );
      return;
    }

    // ✅ Build productNames from selectedProductIds
    _selectedProductNames.clear();
    for (var id in _selectedProductIds) {
      final name = _getProductNameById(id);
      if (name != null) _selectedProductNames.add(name);
    }

    // ✅ Track categories
    Set<String> selectedCategories = {};
    _categoryProductMap.forEach((category, products) {
      for (var id in _selectedProductIds) {
        if (products.containsKey(id)) {
          selectedCategories.add(category);
        }
      }
    });

    // ✅ Add to Firestore
    await FirebaseFirestore.instance.collection('installation_types').add({
      'name': name,
      'productIds': _selectedProductIds.toList(),
      'productNames': _selectedProductNames.toList(), // ✅ Now properly filled
      'categories': selectedCategories.toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    _nameController.clear();
    setState(() => _selectedProductIds.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Installation type created')),
    );
  }


  String? _getProductNameById(String id) {
    for (var category in _categoryProductMap.values) {
      if (category.containsKey(id)) {
        return category[id];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Installation Types')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Panel: Form and Product Selection
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Type Name'),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _categoryProductMap.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : ListView(
                      children: _categoryProductMap.entries.map((entry) {
                        final category = entry.key;
                        final products = entry.value;

                        return ExpansionTile(
                          title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
                          children: products.entries.map((e) {
                            return CheckboxListTile(
                              title: Text(e.value),
                              value: _selectedProductIds.contains(e.key),
                              onChanged: (on) {
                                setState(() {
                                  if (on == true) {
                                    _selectedProductIds.add(e.key);
                                  } else {
                                    _selectedProductIds.remove(e.key);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _createType,
                    child: const Text('Create Installation Type'),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // Right Panel: Existing Types
            Expanded(
              flex: 1,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('installation_types')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Text('No types defined yet.'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data()! as Map<String, dynamic>;
                      final name = data['name'] as String? ?? 'Unnamed';
                      final prodIds = (data['productIds'] as List<dynamic>?)?.cast<String>() ?? [];
                      final categories = (data['categories'] as List<dynamic>?)?.cast<String>() ?? [];

                      final productNames = prodIds
                          .map((id) => _getProductNameById(id))
                          .whereType<String>()
                          .toList();

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (productNames.isNotEmpty)
                                Text('Products: ${productNames.join(', ')}'),
                              if (productNames.isEmpty)
                                const Text('No products or missing data.'),
                              if (categories.isNotEmpty)
                                Text('Categories: ${categories.join(', ')}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => FirebaseFirestore.instance
                                .collection('installation_types')
                                .doc(docs[index].id)
                                .delete(),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
