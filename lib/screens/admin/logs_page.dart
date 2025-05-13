import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  String selectedAction = 'All';

  final List<String> actions = [
    'All',
    'Changed role',
    'Changed status',
  ];

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    final dateTime = timestamp.toDate();
    return DateFormat('yyyy-MM-dd hh:mm a').format(dateTime);
  }

  Stream<QuerySnapshot> getFilteredLogsStream() {
    final logsRef = FirebaseFirestore.instance.collection('logs');

    if (selectedAction == 'All') {
      return logsRef.orderBy('timestamp', descending: true).snapshots();
    } else {
      // Filter using range for prefix match
      return logsRef
          .where('action', isGreaterThanOrEqualTo: selectedAction)
          .where('action', isLessThan: '${selectedAction}z')
          .orderBy('action')
          .orderBy('timestamp', descending: true)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Logs'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Text('Filter by Action: ', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: selectedAction,
                  items: actions.map((String action) {
                    return DropdownMenuItem<String>(
                      value: action,
                      child: Text(action),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedAction = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getFilteredLogsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No logs available.'));
                }

                final logs = snapshot.data!.docs;

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final action = log['action'] ?? 'Unknown action';
                    final changedByEmail = log['changedByEmail'] ?? 'Unknown';
                    final targetEmail = log['targetEmail'] ?? 'Unknown';
                    final timestamp = formatTimestamp(log['timestamp']);

                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(action),
                      subtitle: Text('By: $changedByEmail → $targetEmail\nAt: $timestamp'),
                      isThreeLine: true,
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
