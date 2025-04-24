import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final TextEditingController emailController = TextEditingController();
  String selectedRole = 'user';

  Future<void> addUser() async {
    final email = emailController.text.trim();
    if (email.isNotEmpty) {
      try {
        final newDoc = await FirebaseFirestore.instance.collection('users').add({
          'email': email,
          'role': selectedRole,
          'createdAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User added: ${newDoc.id}')));
        emailController.clear();
        setState(() {}); // Refresh list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> updateUserRole(String docId, String newRole) async {
    await FirebaseFirestore.instance.collection('users').doc(docId).update({
      'role': newRole,
    });
    setState(() {});
  }

  Future<void> deleteUser(String docId) async {
    await FirebaseFirestore.instance.collection('users').doc(docId).delete();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Register New User", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'User Email'),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: selectedRole,
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'user', child: Text('User')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedRole = value);
                  }
                },
              ),
              const SizedBox(width: 16),
              ElevatedButton(onPressed: addUser, child: const Text("Add User")),
            ],
          ),
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 10),
          const Text("Existing Users", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final users = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final docId = user.id;
                    final email = user['email'];
                    final role = user['role'];

                    return ListTile(
                      title: Text(email),
                      subtitle: Row(
                        children: [
                          const Text("Role: "),
                          DropdownButton<String>(
                            value: role,
                            items: const [
                              DropdownMenuItem(value: 'admin', child: Text('Admin')),
                              DropdownMenuItem(value: 'user', child: Text('User')),
                            ],
                            onChanged: (newRole) {
                              if (newRole != null) updateUserRole(docId, newRole);
                            },
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteUser(docId),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
