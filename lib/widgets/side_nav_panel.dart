import 'package:flutter/material.dart';
import '../screens/admin/user_management/user_view.dart';
import '../screens/admin/user_management/user_registration.dart';
import '../screens/admin/product_management/product_view.dart';
import '../screens/admin/product_management/product_registration.dart';
import '../screens/admin/approval/approval_product_addition.dart';
import '../screens/user/inventory_addition.dart';
import '../screens/user/inventory_installation.dart';
import '../screens/user/inventory_view.dart';

class SideNavPanel extends StatelessWidget {
  final String role;

  const SideNavPanel({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.grey[200],
      child: ListView(
        children: [
          const SizedBox(height: 40),
          if (role == 'admin') ...[
            ExpansionTile(
              title: const Text('User Management'),
              children: [
                ListTile(
                  title: const Text('User View'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserViewPage())),
                ),
                ListTile(
                  title: const Text('User Registration'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserRegistrationPage())),
                ),
              ],
            ),
            ExpansionTile(
              title: const Text('Product Management'),
              children: [
                ListTile(
                  title: const Text('Product View'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductViewPage())),
                ),
                ListTile(
                  title: const Text('Product Registration'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductRegistrationPage())),
                ),
              ],
            ),
            ListTile(
              title: const Text('Approvals'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApprovalProductAdditionPage())),
            ),
          ] else if (role == 'user') ...[
            ListTile(
              title: const Text('Inventory Addition'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryAdditionPage())),
            ),
            ListTile(
              title: const Text('Inventory Installation'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryInstallationPage())),
            ),
            ListTile(
              title: const Text('Inventory View'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryViewPage())),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
            ),

          ]
        ],
      ),
    );

  }
}
