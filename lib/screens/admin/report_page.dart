import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:typed_data';

import '../../helpers/report_downloader.dart'; // Adjust if needed

class ReportPage extends StatefulWidget {
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String selectedCollection = 'TemporaryInventoryAdd';
  DateTime? startDate;
  DateTime? endDate;

  final List<String> collectionOptions = [
    'TemporaryInventoryAdd',
    'TemporaryInstallation',
    'InventoryInTransitOut',
    'TemporaryInTransitConfirm'
  ];

  Future<void> pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }

  Future<void> downloadReport() async {
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please select a date range first.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(selectedCollection)
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate)
          .get();

      final userSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final Map<String, String> userMap = {
        for (var doc in userSnapshot.docs)
          doc.id: (doc.data()['email'] ?? 'N/A').toString()
      };

      final allDocs = snapshot.docs;
      final Set<String> allKeys = {};

      for (var doc in allDocs) {
        final data = doc.data();
        allKeys.addAll(data.keys);
      }

      // Ensure consistent key order
      List<String> headers = allKeys.toList()..sort();
      if (!headers.contains('timestamp')) headers.insert(0, 'timestamp');
      if (!headers.contains('userEmail')) headers.add('userEmail');

      List<List<dynamic>> csvData = [headers];

      for (var doc in allDocs) {
        final data = doc.data();
        final Map<String, dynamic> row = {};

        for (var key in headers) {
          if (key == 'timestamp') {
            final ts = data['timestamp'];
            row[key] = ts is Timestamp
                ? DateFormat('yyyy-MM-dd HH:mm:ss').format(ts.toDate())
                : '';
          } else if (key == 'userEmail') {
            final userId = data['requestedBy']?.toString() ?? data['userId']?.toString();
            row[key] = userId != null ? (userMap[userId] ?? 'Unknown') : 'Unknown';
          } else {
            row[key] = data[key]?.toString() ?? '';
          }
        }

        csvData.add(headers.map((key) => row[key] ?? '').toList());
      }

      final csv = const ListToCsvConverter().convert(csvData);
      final bytes = utf8.encode(csv);
      await downloadReportHelper(Uint8List.fromList(bytes), "$selectedCollection-report.csv");

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Report downloaded successfully.'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Download Reports")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              value: selectedCollection,
              onChanged: (value) {
                if (value != null) setState(() => selectedCollection = value);
              },
              items: collectionOptions
                  .map((col) => DropdownMenuItem(value: col, child: Text(col)))
                  .toList(),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: pickDateRange,
              child: Text(
                startDate != null && endDate != null
                    ? 'Selected: ${DateFormat.yMd().format(startDate!)} - ${DateFormat.yMd().format(endDate!)}'
                    : 'Pick Date Range',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: downloadReport,
              icon: Icon(Icons.download),
              label: Text("Download CSV"),
            )
          ],
        ),
      ),
    );
  }
}
