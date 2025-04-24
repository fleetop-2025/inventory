import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> sendNotification(String title, String message, String recipientId) async {
  await FirebaseFirestore.instance.collection('Notifications').add({
    'title': title,
    'message': message,
    'recipient_id': recipientId,
    'timestamp': Timestamp.now(),
  });
}
