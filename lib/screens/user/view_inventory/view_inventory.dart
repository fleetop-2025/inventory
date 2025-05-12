import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewInventoryPage extends StatefulWidget {
  const ViewInventoryPage({Key? key}) : super(key: key);

  @override
  State<ViewInventoryPage> createState() => _ViewInventoryPageState();
}

class _ViewInventoryPageState extends State<ViewInventoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        backgroundColor: Colors.blueGrey,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('inventory').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No inventory available.'));
          }

          final inventoryItems = snapshot.data!.docs;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: inventoryItems.length,
                itemBuilder: (context, index) {
                  final item = inventoryItems[index];
                  final data = item.data() as Map<String, dynamic>;

                  final productName = data['productName'] ?? 'Unnamed Product';
                  final quantity = data['quantity'] ?? 0;
                  final price = data['price']?.toString() ?? 'N/A';
                  final category = data['category'] ?? 'N/A';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.inventory, color: Colors.blueGrey, size: 30),
                      title: Text(
                        productName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Quantity: $quantity'),
                            Text('Price: ₹$price'),
                            Text('Category: $category'),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
