import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class InTransitOutPage extends StatefulWidget {
  const InTransitOutPage({super.key});

  @override
  State<InTransitOutPage> createState() => _InTransitOutPageState();
}

class _InTransitOutPageState extends State<InTransitOutPage> {
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _markAsReceived(String docId, Map<String, dynamic> productData) async {
    if (currentUser == null) return;

    await FirebaseFirestore.instance.collection('TemporaryInventoryAdd').add({
      'productName': productData['productName'],
      'productId': productData['productId'],
      'category': productData['category'],
      'price': productData['price'],
      'quantity': productData['quantity'],
      'requestedBy': currentUser!.uid,
      'status': 'pending', // Again admin has to approve
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Delete from TemporaryInTransitOut once request is raised
    await FirebaseFirestore.instance.collection('TemporaryInTransitOut').doc(docId).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Marked as received and sent for admin approval")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('In-Transit Products (Service)'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('TemporaryInTransitOut')
            .where('requestedBy', isEqualTo: currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No in-transit products.'));
          }

          final products = snapshot.data!.docs;

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final data = products[index].data() as Map<String, dynamic>;
              final docId = products[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(data['productName'] ?? 'Unnamed Product'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Category: ${data['category'] ?? 'N/A'}'),
                      Text('Quantity: ${data['quantity'] ?? '0'}'),
                      Text('Status: ${data['status'] ?? 'N/A'}'),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _markAsReceived(docId, data),
                    child: const Text('Mark Received'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
