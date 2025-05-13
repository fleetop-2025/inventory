import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/login_screen.dart'; // Adjust path if needed

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? centerWidget;

  const CustomAppBar({
    Key? key,
    this.title,
    this.centerWidget,
  }) : super(key: key);

  void _handleLogout(BuildContext context) {
    // Navigate to login screen immediately
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );

    // Then sign out
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: kToolbarHeight,
      backgroundColor: const Color(0xFF222831),
      title: Row(
        children: [
          // Title aligned to the left
          Text(
            title ?? '',
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),

          // Spacer pushes center widget to center
          Expanded(
            child: Center(
              child: centerWidget ?? const SizedBox(),
            ),
          ),

          // Logout button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
