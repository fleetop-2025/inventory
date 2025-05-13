import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  Future<int> countAdmins() async {
    final adminSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Admin')
        .get();
    return adminSnapshot.docs.length;
  }

  Future<void> logAction({
    required String changedByUid,
    required String changedByEmail,
    required String targetUid,
    required String targetEmail,
    required String action,
  }) async {
    await FirebaseFirestore.instance.collection('logs').add({
      'changedByUid': changedByUid,
      'changedByEmail': changedByEmail,
      'targetUid': targetUid,
      'targetEmail': targetEmail,
      'action': action,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserRole(
      String uid,
      String newRole,
      String currentRole,
      String targetEmail,
      ) async {
    if (currentRole == 'Admin' && newRole == 'User') {
      final adminCount = await countAdmins();

      if (uid == currentUser?.uid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You cannot change your own role.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (adminCount <= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
            Text('At least one Admin must remain. Cannot change the last Admin to User.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'role': newRole,
    });

    await logAction(
      changedByUid: currentUser!.uid,
      changedByEmail: currentUser!.email ?? 'Unknown',
      targetUid: uid,
      targetEmail: targetEmail,
      action: 'Changed role from $currentRole to $newRole',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Role updated')),
    );
  }

  Future<void> updateUserStatus(
      String uid,
      String newStatus,
      String targetEmail,
      String currentStatus,
      ) async {
    if (uid == currentUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot change your own status.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'status': newStatus,
    });

    await logAction(
      changedByUid: currentUser!.uid,
      changedByEmail: currentUser!.email ?? 'Unknown',
      targetUid: uid,
      targetEmail: targetEmail,
      action: 'Changed status from $currentStatus to $newStatus',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Status updated')),
    );
  }

  Widget buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs;

        if (users.isEmpty) {
          return const Center(child: Text('No users found.'));
        }

        return ListView.builder(
          itemCount: users.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final user = users[index];
            final uid = user.id;
            final email = user['email'] ?? 'Unknown Email';

            // Normalize role and status values
            final rawRole = (user['role'] ?? 'User').toString();
            final role = rawRole[0].toUpperCase() + rawRole.substring(1).toLowerCase();

            final rawStatus = (user['status'] ?? 'active').toString();
            final status = rawStatus[0].toLowerCase() == 'i' ? 'inactive' : 'active';

            final isSelf = uid == currentUser?.uid;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Details
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(email, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Role: $role'),
                          Text('Status: ${status[0].toUpperCase()}${status.substring(1)}'),
                        ],
                      ),
                    ),

                    // Dropdowns
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Tooltip(
                            message: isSelf
                                ? 'You cannot change your own role'
                                : 'Change user role',
                            child: AbsorbPointer(
                              absorbing: isSelf,
                              child: DropdownButton<String>(
                                value: ['User', 'Admin'].contains(role) ? role : 'User',
                                items: const [
                                  DropdownMenuItem(value: 'User', child: Text('User')),
                                  DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                                ],
                                onChanged: (value) {
                                  if (value != null && value != role) {
                                    updateUserRole(uid, value, role, email);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Tooltip(
                            message: isSelf
                                ? 'You cannot change your own status'
                                : 'Change user status',
                            child: AbsorbPointer(
                              absorbing: isSelf,
                              child: DropdownButton<String>(
                                value: ['active', 'inactive'].contains(status)
                                    ? status
                                    : 'active',
                                items: const [
                                  DropdownMenuItem(value: 'active', child: Text('Active')),
                                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                                ],
                                onChanged: (value) {
                                  if (value != null && value != status) {
                                    updateUserStatus(uid, value, email, status);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "All Users",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              buildUserList(),
            ],
          ),
        ),
      ),
    );
  }
}
