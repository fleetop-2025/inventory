import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReceivedProductsPage extends StatefulWidget {
  const ReceivedProductsPage({super.key});

  @override
  State<ReceivedProductsPage> createState() => _ReceivedProductsPageState();
}

class _ReceivedProductsPageState extends State<ReceivedProductsPage> {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  Future<void> markAsReceived(String docId, Map<String, dynamic> data) async {
    final firestore = FirebaseFirestore.instance;

    try {
      // Move the document to InventoryInTransitOut
      await firestore.collection('InventoryInTransitOut').add({
        'productName': data['productName'],
        'productId': data['productId'],
        'category': data['category'],
        'price': data['price'],
        'quantity': data['quantity'],
        'requestedBy': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending', // Waiting for Admin Approval
      });

      // Delete the document from TemporaryInTransitConfirm
      await firestore.collection('TemporaryInTransitConfirm').doc(docId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product marked as received successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      return const Center(child: Text('User not logged in.'));
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SizedBox(
          width: 600, // max width for centering the content
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('TemporaryInTransitConfirm')
                .where('requestedBy', isEqualTo: currentUserId)
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return const Center(child: Text('No products awaiting confirmation.'));
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Products Awaiting Confirmation",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(data['productName'] ?? 'Unknown Product'),
                            subtitle: Text('Quantity: ${data['quantity'] ?? '-'}'),
                            trailing: ElevatedButton(
                              onPressed: () => markAsReceived(doc.id, data),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text('Received'),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
