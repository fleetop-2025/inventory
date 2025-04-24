import 'package:flutter/material.dart';
import '../add_inventory/add_inventory.dart';
import '../request_installation/request_installation.dart';
import '../view_inventory/view_inventory.dart';
import '../../widgets/notifications_page.dart';
import '../../widgets/collapsible_sidebar.dart';
import '../../widgets/custom_appbar.dart'; // Custom AppBar with logout

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
    'Notifications',
  ];

  Widget _getPage(String page) {
    switch (page) {
      case 'Dashboard':
        return const Center(child: Text('User Dashboard Graphs/Stats here'));
      case 'Inventory':
        return const ViewInventoryPage();
      case 'Add Inventory':
        return const AddInventoryPage();
      case 'Request Installation':
        return const RequestInstallationPage();
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
            onToggleCollapse: () => setState(() => _isCollapsed = !_isCollapsed),
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
