import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../helpers/utils.dart'; // For sendNotification()

class ApprovalPage extends StatefulWidget {
  const ApprovalPage({super.key});

  @override
  State<ApprovalPage> createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage> {
  final Map<String, String> _userEmailMap = {};
  bool _isLoading = true;
  List<Map<String, dynamic>> _lowStockItems = [];

  @override
  void initState() {
    super.initState();
    _fetchUserEmails();
    _fetchLowStockItems();
  }

  Future<void> _fetchUserEmails() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users')
          .get();
      final Map<String, String> tempMap = {};
      for (var doc in snapshot.docs) {
        tempMap[doc.id] = doc.data()['email'] ?? 'No Email';
      }
      setState(() {
        _userEmailMap.addAll(tempMap);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user emails: $e')),
      );
    }
  }

  Future<void> _fetchLowStockItems() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('inventory')
          .where('quantity', isLessThanOrEqualTo: 5)
          .get();

      final List<Map<String, dynamic>> lowStock = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'productName': data['productName'] ?? 'Unknown',
          'quantity': data['quantity'] ?? 0,
        };
      }).toList();

      setState(() {
        _lowStockItems = lowStock;
      });
    } catch (e) {
      print('Error fetching low stock items: $e');
    }
  }

  Future<void> rejectRequest(String docId, String collection,
      String userId) async {
    try {
      await FirebaseFirestore.instance.collection(collection).doc(docId).update(
          {
            'status': 'rejected',
          });

      await sendNotification(
        "Request Rejected",
        "Your ${_getRequestTypeText(collection)} request has been rejected.",
        userId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting request: $e')),
      );
    }
  }

  String _getRequestTypeText(String collection) {
    switch (collection) {
      case 'TemporaryInventoryAdd':
        return 'inventory addition';
      case 'TemporaryInstallation':
        return 'installation';
      case 'TemporaryInTransitOut':
        return 'in-transit product';
      case 'InventoryInTransitOut':
        return 'inventory addition';
      default:
        return 'request';
    }
  }

  Future<void> approveRequest(String docId, String collection, String userId,
      Map<String, dynamic> data) async {
    final firestore = FirebaseFirestore.instance;

    try {
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
            'productId': data['productId'] ?? '',
            'category': data['category'] ?? '',
            'price': data['price'] ?? 0,
            'quantity': addedQuantity,
            'requestedBy': userId,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      } else if (collection == 'TemporaryInstallation') {
        final String productName = data['productName'];
        final int requestedQuantity = data['quantity'];

        final query = await firestore
            .collection('inventory')
            .where('productName', isEqualTo: productName)
            .get();

        if (query.docs.isEmpty) {
          await sendNotification(
            "Installation Rejected",
            "Product $productName not found in inventory.",
            userId,
          );
          await rejectRequest(docId, collection, userId);
          return;
        }

        final doc = query.docs.first;
        final inventoryData = doc.data();
        final currentQty = inventoryData['quantity'] ?? 0;

        if (currentQty < requestedQuantity) {
          await sendNotification(
            "Installation Rejected",
            "Insufficient quantity of $productName in inventory.",
            userId,
          );
          await rejectRequest(docId, collection, userId);
          return;
        }

        await firestore.collection('inventory').doc(doc.id).update({
          'quantity': currentQty - requestedQuantity,
        });
      } else if (collection == 'TemporaryInTransitOut') {
        final String productName = data['productName'];
        final int receivedQuantity = data['quantity'];

        await firestore.collection('TemporaryInTransitConfirm').add({
          'productName': productName,
          'productId': data['productId'] ?? '',
          'category': data['category'] ?? '',
          'price': data['price'] ?? 0,
          'quantity': receivedQuantity,
          'requestedBy': userId,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else if (collection == 'InventoryInTransitOut') {
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
            'productId': data['productId'] ?? '',
            'category': data['category'] ?? '',
            'price': data['price'] ?? 0,
            'quantity': addedQuantity,
            'requestedBy': userId,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }

      await firestore.collection(collection).doc(docId).update({
        'status': 'approved',
      });

      await sendNotification(
        "Request Approved",
        "Your ${_getRequestTypeText(collection)} request has been approved.",
        userId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request approved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving request: $e')),
      );
    }
  }

  Widget buildRequestList(String collectionName, String title) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collectionName)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const SizedBox();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            Row(
              children: [
                const Expanded(
                  child: Divider(
                      thickness: 2, color: Colors.blueGrey, endIndent: 8),
                ),
                Text(
                  title,
                  style: const TextStyle(fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey),
                ),
                const Expanded(
                  child: Divider(
                      thickness: 2, color: Colors.blueGrey, indent: 8),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final requesterEmail = _userEmailMap[data['requestedBy']] ??
                  'Unknown';
              final quantity = data['quantity'] ?? 'N/A';

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 16),
                    child: ListTile(
                      title: Text(data['productName'] ?? 'Unknown Product'),
                      subtitle: Text(
                          'Requested by: $requesterEmail\nQuantity: $quantity'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => approveRequest(
                                doc.id, collectionName, data['requestedBy'],
                                data),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => rejectRequest(
                                doc.id, collectionName, data['requestedBy']),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              // Low stock alert at the top
              if (_lowStockItems.isNotEmpty)
                Card(
                  color: Colors.red.shade100,
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "⚠️ Low Stock Alerts",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight
                              .bold, color: Colors.red),
                        ),
                        const SizedBox(height: 10),
                        ..._lowStockItems.map((item) =>
                            Text(
                              "• ${item['productName']} - Only ${item['quantity']} left. Please order more.",
                              style: const TextStyle(fontSize: 16),
                            )),
                      ],
                    ),
                  ),
                ),

              // Request sections
              buildRequestList(
                  'TemporaryInventoryAdd', 'Inventory Addition Requests'),
              buildRequestList(
                  'TemporaryInstallation', 'Installation Requests'),
              buildRequestList(
                  'TemporaryInTransitOut', 'In-Transit Product Confirmations'),
              buildRequestList(
                  'InventoryInTransitOut', 'In-Transit Inventory Additions'),
            ],
          ),
        ),
      ),
    );
  }
}
