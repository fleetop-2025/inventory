import 'package:flutter/material.dart';

class CollapsibleSidebar extends StatelessWidget {
  final bool isCollapsed;
  final Function(String) onItemSelected;
  final Function() onToggle;
  final String selectedItem;
  final List<String> items; // ✅ Use List<String> instead of dynamic

  const CollapsibleSidebar({
    super.key,
    required this.isCollapsed,
    required this.onItemSelected,
    required this.onToggle,
    required this.selectedItem,
    required this.items, // ✅ keep this
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isCollapsed ? 70 : 240,
      decoration: const BoxDecoration(
        color: Color(0xFF222831),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 24),
              children: items.map((item) {
                final isSelected = item == selectedItem;
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isCollapsed ? 12 : 16,
                    vertical: 4,
                  ),
                  leading: Icon(
                    _getIconForItem(item),
                    color: Colors.white,
                    size: 20,
                  ),
                  title: isCollapsed
                      ? null
                      : Text(
                    item,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  selected: isSelected,
                  selectedTileColor: Colors.deepOrange,
                  onTap: () => onItemSelected(item),
                  dense: true,
                );
              }).toList(),
            ),
          ),

          // Collapse / Expand Button at Bottom
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: IconButton(
                icon: Icon(
                  isCollapsed ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
                  color: Colors.white70,
                  size: 18,
                ),
                onPressed: onToggle,
                tooltip: isCollapsed ? 'Expand' : 'Collapse',
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForItem(String item) {
    switch (item) {
      case 'Dashboard':
        return Icons.dashboard;
      case 'Products':
        return Icons.list;
      case 'Register Product':
        return Icons.add_box;
      case 'Approvals':
        return Icons.verified;
      case 'Users':
        return Icons.group;
      case 'Register User':
        return Icons.person_add;
      case 'Installations':
        return Icons.settings_input_component;
      case 'Notifications':
        return Icons.notifications;
      case 'Installation Type':
        return Icons.extension;
      case 'Inventory':
        return Icons.inventory_2;
      case 'Add Inventory':
        return Icons.playlist_add;
      case 'Request Installation':
        return Icons.build;
      case 'Logs':
        return Icons.receipt_long;
      case 'Reports':
        return Icons.insert_chart_outlined;
      case 'Category Management':
        return Icons.category;
      default:
        return Icons.help;
    }
  }
}
