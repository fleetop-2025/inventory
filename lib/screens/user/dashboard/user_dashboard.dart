import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Correct conditional import
import 'package:inventory/widgets/download_csv.dart';

import '../add_inventory/add_inventory.dart';
import '../request_installation/request_installation.dart';
import '../view_inventory/view_inventory.dart';
import '../received_products/received_products.dart';
import 'package:inventory/widgets/notifications_page.dart';
import 'package:inventory/widgets/collapsible_sidebar.dart';
import 'package:inventory/widgets/custom_appbar.dart';

class UserDashboard extends StatefulWidget {
  final VoidCallback onLogout;
  const UserDashboard({super.key, required this.onLogout});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  String _selectedItem = 'Dashboard';
  bool _isCollapsed = false;

  final List<String> _menuItems = [
    'Dashboard',
    'Inventory',
    'Add Inventory',
    'Request Installation',
    'Received Products',
    'Notifications',
  ];

  Map<String, int> inventorySummary = {};
  Map<String, int> requestStats = {};
  Map<String, int> userRoles = {};

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    final inventorySnapshot = await FirebaseFirestore.instance.collection('inventory').get();
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    final tempInstallSnapshot = await FirebaseFirestore.instance.collection('TemporaryInstallation').get();

    final Map<String, int> inventory = {};
    final Map<String, int> roles = {};
    final Map<String, int> requests = {'approved': 0, 'rejected': 0, 'pending': 0};

    for (var doc in inventorySnapshot.docs) {
      final name = doc.data()['productName'] ?? 'Unknown';
      final qty = doc.data()['quantity'] ?? 0;
      inventory[name] = qty;
    }

    for (var doc in usersSnapshot.docs) {
      final role = doc.data()['role'] ?? 'Unknown';
      roles[role] = (roles[role] ?? 0) + 1;
    }

    for (var doc in tempInstallSnapshot.docs) {
      final status = doc.data()['status'] ?? 'pending';
      requests[status] = (requests[status] ?? 0) + 1;
    }

    setState(() {
      inventorySummary = inventory;
      userRoles = roles;
      requestStats = requests;
    });
  }

  Future<void> exportLogs(BuildContext context) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('TemporaryInstallation')
          .get();

      List<List<String>> rows = [
        ['Product Name', 'Quantity', 'Requested By', 'Status'],
      ];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        rows.add([
          data['productName'] ?? '',
          '${data['quantity'] ?? ''}',
          data['requestedBy'] ?? '',
          data['status'] ?? '',
        ]);
      }

      final csvContent = const ListToCsvConverter().convert(rows);

      if (kIsWeb) {
        downloadCSV(rows, 'user_report.csv');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV download started')),
        );
      } else {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission denied')),
          );
          return;
        }

        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/user_report.csv';
        final file = File(filePath);
        await file.writeAsString(csvContent);

        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'User Report CSV attached',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sharing CSV file...')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export report: $e')),
      );
    }
  }

  Widget buildBarChart(Map<String, int> data, String title) {
    final items = data.entries.toList();
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= items.length) return const Text('');
                          return Text(items[value.toInt()].key, style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: items.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(toY: entry.value.value.toDouble(), color: Colors.blue),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPieChart(Map<String, int> data, String title) {
    final total = data.values.fold(0, (a, b) => a + b);
    final sections = data.entries.map((entry) {
      return PieChartSectionData(
        title: '${entry.key} (${entry.value})',
        value: entry.value.toDouble(),
        color: entry.key == 'admin' ? Colors.red : Colors.green,
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12),
      );
    }).toList();

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 200,
              child: PieChart(PieChartData(sections: sections)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getPage(String page) {
    switch (page) {
      case 'Dashboard':
        return RefreshIndicator(
          onRefresh: fetchDashboardData,
          child: ListView(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => exportLogs(context),
                    child: const Text('Download CSV'),
                  ),
                ],
              ),
              if (inventorySummary.isNotEmpty) buildBarChart(inventorySummary, 'Inventory Quantities'),
              if (userRoles.isNotEmpty) buildPieChart(userRoles, 'User Role Distribution'),
              if (requestStats.isNotEmpty) buildBarChart(requestStats, 'Request Status Summary'),
            ],
          ),
        );
      case 'Inventory':
        return const ViewInventoryPage();
      case 'Add Inventory':
        return const AddInventoryPage();
      case 'Request Installation':
        return const RequestInstallationPage();
      case 'Received Products':
        return const ReceivedProductsPage();
      case 'Notifications':
        return const NotificationsPage();
      default:
        return const Center(child: Text("Page not found"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(onLogout: widget.onLogout, title: 'User Dashboard'),
      body: Row(
        children: [
          CollapsibleSidebar(
            selectedItem: _selectedItem,
            onItemSelected: (item) => setState(() => _selectedItem = item),
            isCollapsed: _isCollapsed,
            onToggle: () => setState(() => _isCollapsed = !_isCollapsed),
            items: _menuItems,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _getPage(_selectedItem),
            ),
          ),
        ],
      ),
    );
  }
}
