import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:typed_data';

import '../../helpers/report_downloader.dart'; // Adjust path as needed

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
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(selectedCollection)
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate)
          .get();

      final userSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final userMap = {
        for (var doc in userSnapshot.docs) doc.id: doc['email'] ?? 'N/A'
      };

      final allDocs = snapshot.docs.map((doc) => doc.data()).toList();

      final Set<String> allKeys = {};
      for (var data in allDocs) {
        allKeys.addAll(data.keys);
      }

      allKeys.add('timestamp');
      allKeys.add('userEmail');

      final headers = allKeys.toList();
      List<List<dynamic>> csvData = [headers];

      for (var data in allDocs) {
        Map<String, dynamic> rowMap = {};

        for (var key in headers) {
          var value = data[key];

          if (key == 'timestamp' && value is Timestamp) {
            rowMap[key] = DateFormat('yyyy-MM-dd HH:mm:ss').format(value.toDate());
          } else if (key == 'userEmail') {
            String? userId = data['requestedBy']?.toString();
            rowMap[key] = userId != null ? (userMap[userId] ?? 'Unknown') : 'Unknown';
          } else {
            rowMap[key] = value != null ? value.toString() : '';
          }
        }

        List<dynamic> row = headers.map((key) => rowMap[key] ?? '').toList();
        csvData.add(row);
      }

      final csv = const ListToCsvConverter().convert(csvData);
      final bytes = utf8.encode(csv);
      await downloadReportHelper(Uint8List.fromList(bytes), "$selectedCollection-report.csv");

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Report downloaded successfully.'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
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
