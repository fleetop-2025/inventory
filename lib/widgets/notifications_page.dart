import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('Notifications').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var notif = notifications[index];
              return Card(
                child: ListTile(
                  title: Text(notif['title']),
                  subtitle: Text(notif['message']),
                  trailing: Text(notif['timestamp'].toDate().toString().split(".")[0]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
