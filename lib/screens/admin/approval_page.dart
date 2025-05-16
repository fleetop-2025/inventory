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
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      final Map<String, String> tempMap = {};
      for (var doc in snapshot.docs) {
        tempMap[doc.id] = doc.data()['email'] ?? 'No Email';
      }
      setState(() {
        _userEmailMap.addAll(tempMap);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
      setState(() => _lowStockItems = lowStock);
    } catch (e) {
      print('Error fetching low stock items: $e');
    }
  }

  Future<void> rejectRequest(String docId, String collection, String userId) async {
    try {
      await FirebaseFirestore.instance.collection(collection).doc(docId).update({'status': 'rejected'});
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

  Future<void> approveRequest(String docId, String collection, String userId, Map<String, dynamic> data) async {
    final firestore = FirebaseFirestore.instance;

    try {
      if (collection == 'TemporaryInventoryAdd') {
        final String productName = data['productName'];
        final int addedQuantity = data['quantity'];

        final query = await firestore.collection('inventory').where('productName', isEqualTo: productName).get();
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
        final String installationTypeId = data['installation_type_id'] ?? '';
        final int panicButtonQty = data['panic_quantity'] ?? 0;

        final installationTypeDoc = await firestore.collection('installation_types').doc(installationTypeId).get();
        if (!installationTypeDoc.exists) {
          await sendNotification("Installation Rejected", "Installation type not found.", userId);
          await rejectRequest(docId, collection, userId);
          return;
        }

        final List<dynamic> productNames = installationTypeDoc.data()?['productNames'] ?? [];
        final List<dynamic> categories = installationTypeDoc.data()?['categories'] ?? [];

        // Step 1: Validate inventory
        for (int i = 0; i < productNames.length; i++) {
          final productName = productNames[i].toString();
          final category = (i < categories.length) ? categories[i].toString() : '';
          final requiredQty = category == 'Panic Buttons' ? panicButtonQty : 1;

          final inventoryQuery = await firestore.collection('inventory')
              .where('productName', isEqualTo: productName)
              .get();

          if (inventoryQuery.docs.isEmpty || (inventoryQuery.docs.first.data()['quantity'] ?? 0) < requiredQty) {
            await sendNotification("Installation Rejected", "Insufficient stock for $productName.", userId);
            await rejectRequest(docId, collection, userId);
            return;
          }
        }

        // Step 2: Deduct quantities
        for (int i = 0; i < productNames.length; i++) {
          final productName = productNames[i].toString();
          final category = (i < categories.length) ? categories[i].toString() : '';
          final requiredQty = category == 'Panic Buttons' ? panicButtonQty : 1;

          final inventoryQuery = await firestore.collection('inventory')
              .where('productName', isEqualTo: productName)
              .get();

          final doc = inventoryQuery.docs.first;
          final currentQty = doc.data()['quantity'] ?? 0;
          await firestore.collection('inventory').doc(doc.id).update({
            'quantity': currentQty - requiredQty
          });
        }

      } else if (collection == 'TemporaryInTransitOut') {
        await firestore.collection('TemporaryInTransitConfirm').add({
          'productName': data['productName'],
          'productId': data['productId'] ?? '',
          'category': data['category'] ?? '',
          'price': data['price'] ?? 0,
          'quantity': data['quantity'],
          'requestedBy': userId,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });

      } else if (collection == 'InventoryInTransitOut') {
        final productName = data['productName'];
        final addedQuantity = data['quantity'];

        final query = await firestore.collection('inventory').where('productName', isEqualTo: productName).get();
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

      await firestore.collection(collection).doc(docId).update({'status': 'approved'});

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
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const SizedBox();

        return Column(
          children: [
            const SizedBox(height: 30),
            Row(
              children: [
                const Expanded(child: Divider(thickness: 2, color: Colors.blueGrey, endIndent: 8)),
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                const Expanded(child: Divider(thickness: 2, color: Colors.blueGrey, indent: 8)),
              ],
            ),
            const SizedBox(height: 16),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final requesterEmail = _userEmailMap[data['requestedBy']] ?? 'Unknown';
              if (collectionName == 'TemporaryInstallation') {
                return InstallationTypeRequestTile(
                  docId: doc.id,
                  data: data,
                  userEmail: requesterEmail,
                  approveRequest: approveRequest,
                  rejectRequest: rejectRequest,
                );
              }
              final quantity = data['quantity'] ?? 'N/A';
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(data['productName'] ?? 'Unknown Product'),
                  subtitle: Text('Requested by: $requesterEmail\nQuantity: $quantity'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => approveRequest(doc.id, collectionName, data['requestedBy'], data)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => rejectRequest(doc.id, collectionName, data['requestedBy'])),
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_lowStockItems.isNotEmpty)
          Card(
            color: Colors.red.shade100,
            margin: const EdgeInsets.only(bottom: 20),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("⚠️ Low Stock Alerts", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 10),
                  ..._lowStockItems.map((item) => Text("• ${item['productName']} - Only ${item['quantity']} left. Please order more.", style: const TextStyle(fontSize: 16))),
                ],
              ),
            ),
          ),
        buildRequestList('TemporaryInventoryAdd', 'Inventory Addition Requests'),
        buildRequestList('TemporaryInstallation', 'Installation Requests'),
        buildRequestList('TemporaryInTransitOut', 'Transit Requests'),
        buildRequestList('InventoryInTransitOut', 'Inventory InTransit Addition Requests'),
      ],
    );
  }
}

class InstallationTypeRequestTile extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String userEmail;
  final Function(String, String, String, Map<String, dynamic>) approveRequest;
  final Function(String, String, String) rejectRequest;

  const InstallationTypeRequestTile({
    super.key,
    required this.docId,
    required this.data,
    required this.userEmail,
    required this.approveRequest,
    required this.rejectRequest,
  });

  @override
  Widget build(BuildContext context) {
    final String installationTypeId = data['installation_type_id'] ?? '';
    final String userId = data['requestedBy'];

    return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('installation_types').doc(
            installationTypeId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          if (!snapshot.data!.exists)
            return const Text("Installation type not found");

          final docData = snapshot.data!.data() as Map<String, dynamic>;
          final typeName = docData['name'] ?? 'Unknown Type';
          final List<dynamic> productNames = docData['productNames'] ?? [];
          final List<dynamic> categories = docData['categories'] ?? [];
          // 🧠 Now we chain a second FutureBuilder to get the user email
          return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users')
                  .doc(userId)
                  .get(),
              builder: (context, userSnapshot) {
                String requestedByEmail = "Unknown";

                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final userData = userSnapshot.data!.data() as Map<
                      String,
                      dynamic>;
                  requestedByEmail = userData['email'] ?? 'Unknown';
                }
                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Type: $typeName",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Requested by: $userEmail",
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        const Text("Products:"),
                        ...List.generate(productNames.length, (index) {
                          final name = productNames[index].toString();
                          final category = (index < categories.length) ? categories[index].toString() : '';
                          final isPanicButton = category == 'Panic Buttons';
                          final qty = isPanicButton ? (data['panic_quantity'] ?? 0) : 1;

                          return Text("• $name (Qty: $qty)");
                        }),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(
                                  Icons.check, color: Colors.green),
                              onPressed: () =>
                                  approveRequest(
                                      docId, 'TemporaryInstallation', userId,
                                      data),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () =>
                                  rejectRequest(
                                      docId, 'TemporaryInstallation', userId),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              }
          );
        }
    );
  }
}
