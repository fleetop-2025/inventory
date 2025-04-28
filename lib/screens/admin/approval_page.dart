import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../helpers/utils.dart'; // Optional: for sendNotification()

class ApprovalPage extends StatefulWidget {
  const ApprovalPage({super.key});

  @override
  State<ApprovalPage> createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage> {
  final Map<String, String> _userEmailMap = {};

  @override
  void initState() {
    super.initState();
    _fetchUserEmails();
  }

  Future<void> _fetchUserEmails() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    final Map<String, String> tempMap = {};
    for (var doc in snapshot.docs) {
      tempMap[doc.id] = doc.data()['email'] ?? 'No Email';
    }
    setState(() {
      _userEmailMap.addAll(tempMap);
    });
  }

  Future<void> approveRequest(
      String docId, String collection, String userId, Map<String, dynamic> data) async {
    final firestore = FirebaseFirestore.instance;

    if (collection == 'TemporaryInventoryAdd') {
      final String productName = data['productName'];
      final int addedQuantity = data['quantity'];

      final query = await firestore
          .collection('inventory')
          .where('productName', isEqualTo: productName)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final currentQty = doc.data()['quantity'] ?? 0;
        await firestore.collection('inventory').doc(doc.id).update({
          'quantity': currentQty + addedQuantity,
        });
      } else {
        await firestore.collection('inventory').add({
          'productName': productName,
          'quantity': addedQuantity,
          'requestedBy': data['requestedBy'],
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }

    if (collection == 'TemporaryInstallation') {
      final String productName = data['productName'];
      final int requestedQuantity = data['quantity'];

      final query = await firestore
          .collection('inventory')
          .where('productName', isEqualTo: productName)
          .get();

      if (query.docs.isEmpty) {
        await sendNotification("Installation Rejected",
            "Product $productName not found in inventory.", userId);
        await rejectRequest(docId, collection, userId);
        return;
      }

      final doc = query.docs.first;
      final inventoryData = doc.data();
      final currentQty = inventoryData['quantity'] ?? 0;

      if (currentQty < requestedQuantity) {
        await sendNotification("Installation Rejected",
            "Insufficient quantity of $productName in inventory.", userId);
        await rejectRequest(docId, collection, userId);
        return;
      }

      await firestore.collection('inventory').doc(doc.id).update({
        'quantity': currentQty - requestedQuantity,
      });
    }

    if (collection == 'TemporaryInTransitOut') {
      final String productName = data['productName'];
      final int servicedQuantity = data['quantity'];

      final query = await firestore
          .collection('inventory')
          .where('productName', isEqualTo: productName)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final currentQty = doc.data()['quantity'] ?? 0;
        await firestore.collection('inventory').doc(doc.id).update({
          'quantity': currentQty + servicedQuantity,
        });
      } else {
        await firestore.collection('inventory').add({
          'productName': productName,
          'quantity': servicedQuantity,
          'requestedBy': data['requestedBy'],
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }

    await firestore.collection(collection).doc(docId).update({
      'status': 'approved',
    });

    await sendNotification(
      "Request Approved",
      "Your ${collection == 'TemporaryInventoryAdd' ? 'inventory addition' : collection == 'TemporaryInstallation' ? 'installation' : 'in-transit servicing'} request has been approved.",
      userId,
    );
  }

  Future<void> rejectRequest(String docId, String collection, String userId) async {
    await FirebaseFirestore.instance.collection(collection).doc(docId).update({
      'status': 'rejected',
    });

    await sendNotification(
      "Request Rejected",
      "Your request has been rejected by the admin.",
      userId,
    );
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
              final requestedById = data['requestedBy'];
              final requesterEmail = _userEmailMap[requestedById] ?? 'Unknown';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(data['productName'] ?? 'Unknown Product'),
                  subtitle: Text(
                    'Requested by: $requesterEmail\nQuantity: ${data['quantity'] ?? '-'}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => approveRequest(doc.id, collectionName, requestedById, data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => rejectRequest(doc.id, collectionName, requestedById),
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
          buildRequestList('TemporaryInventoryAdd', 'Inventory Addition'),
          const SizedBox(height: 20),
          buildRequestList('TemporaryInstallation', 'Installation'),
          const SizedBox(height: 20),
          buildRequestList('TemporaryInTransitOut', 'In-Transit Servicing'), // NEW
        ],
      ),
    );
  }
}
