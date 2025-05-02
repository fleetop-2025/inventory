import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:inventory/widgets/download_csv.dart';

import 'package:inventory/widgets/collapsible_sidebar.dart';
import '../user_management.dart';
import '../approval_page.dart';
import 'package:inventory/widgets/notifications_page.dart';
import '../product_registration.dart';
import '../product_view.dart';
import '../user_registration.dart';
import 'package:inventory/widgets/custom_appbar.dart';

class AdminDashboard extends StatefulWidget {
  final VoidCallback onLogout;

  const AdminDashboard({super.key, required this.onLogout});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _selectedItem = 'Dashboard';
  bool _isCollapsed = false;

  final List<String> _menuItems = [
    'Dashboard',
    'Inventory',
    'Register Product',
    'Approvals',
    'Users',
    'Register User',
    'Notifications',
  ];

  Map<String, int> inventorySummary = {};
  Map<String, int> userRoles = {};
  Map<String, int> requestStats = {};

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

  Future<void> pickDateAndExportLogs(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      await exportLogs(context, picked);
    }
  }

  Future<void> exportLogs(BuildContext context, DateTimeRange dateRange) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('TemporaryInstallation')
          .where('timestamp', isGreaterThanOrEqualTo: dateRange.start)
          .where('timestamp', isLessThanOrEqualTo: dateRange.end)
          .get();

      List<List<String>> rows = [
        ['Product Name', 'Quantity', 'Requested By', 'Status', 'Date'],
      ];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] != null
            ? (data['timestamp'] as Timestamp).toDate()
            : null;
        rows.add([
          data['productName'] ?? '',
          '${data['quantity'] ?? ''}',
          data['requestedBy'] ?? '',
          data['status'] ?? '',
          timestamp != null ? timestamp.toString() : '',
        ]);
      }

      final csvContent = const ListToCsvConverter().convert(rows);

      if (kIsWeb) {
        downloadCSV(rows, 'admin_report.csv'); // Web download
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
        final filePath = '${directory.path}/admin_report.csv';
        final file = File(filePath);
        await file.writeAsString(csvContent);

        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'Admin Report CSV attached',
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
                  ElevatedButton.icon(
                    onPressed: () => pickDateAndExportLogs(context),
                    icon: const Icon(Icons.download),
                    label: const Text('Export Report'),
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
        return const ProductViewPage();
      case 'Approvals':
        return const ApprovalPage();
      case 'Users':
        return const UserManagementPage();
      case 'Register Product':
        return const ProductRegistrationPage();
      case 'Register User':
        return const UserRegistrationPage();
      case 'Notifications':
        return const NotificationsPage();
      default:
        return const Center(child: Text("Page not found"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        onLogout: widget.onLogout,
        title: 'Admin Dashboard',
      ),
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _getPage(_selectedItem),
            ),
          ),
        ],
      ),
    );
  }
}
