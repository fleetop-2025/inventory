import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  Future<void> updateUserRole(String uid, String newRole) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'role': newRole.toLowerCase()});
  }

  Future<void> updateUserStatus(String uid, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'status': newStatus.toLowerCase()});
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
            final role = (user['role'] ?? 'user').toString().toLowerCase();
            final status = (user['status'] ?? 'active').toString().toLowerCase();

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
                          Text('Role: ${role[0].toUpperCase()}${role.substring(1)}'),
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
                          DropdownButton<String>(
                            value: role,
                            items: const [
                              DropdownMenuItem(value: 'user', child: Text('User')),
                              DropdownMenuItem(value: 'admin', child: Text('Admin')),
                            ],
                            onChanged: (value) {
                              if (value != null && value != role) {
                                updateUserRole(uid, value);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Role updated')),
                                );
                              }
                            },
                          ),
                          DropdownButton<String>(
                            value: status,
                            items: const [
                              DropdownMenuItem(value: 'active', child: Text('Active')),
                              DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                            ],
                            onChanged: (value) {
                              if (value != null && value != status) {
                                updateUserStatus(uid, value);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Status updated')),
                                );
                              }
                            },
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
    return SingleChildScrollView(
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
    );
  }
}
