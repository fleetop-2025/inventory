import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../helpers/utils.dart'; // Adjust path to match your project


class ApprovalPage extends StatelessWidget {
  const ApprovalPage({super.key});

  Future<void> approveRequest(String docId, String collection, String userId) async {
    await FirebaseFirestore.instance.collection(collection).doc(docId).update({
      'status': 'approved',
    });

    await sendNotification(
      "Request Approved",
      "Your request has been approved by Admin.",
      userId,
    );
  }


  Future<void> rejectRequest(String docId, String collection) async {
    await FirebaseFirestore.instance.collection(collection).doc(docId).update({
      'status': 'rejected',
    });
  }

  Widget buildRequestList(String collectionName, String title) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collectionName)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Text('No pending $title requests');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$title Requests', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(data['productName'] ?? 'Unknown Product'),
                  subtitle: Text('Requested by: ${data['requestedBy'] ?? 'N/A'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => approveRequest(doc.id, collectionName, data['requestedBy']),

                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => rejectRequest(doc.id, collectionName),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          buildRequestList('inventory_add_requests', 'Inventory Addition'),
          const SizedBox(height: 20),
          buildRequestList('installation_requests', 'Installation'),
        ],
      ),
    );
  }
}
