import 'package:flutter/material.dart';
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

  Widget _getPage(String page) {
    switch (page) {
      case 'Dashboard':
        return const Center(child: Text('Admin Dashboard'));
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
