import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onLogout;
  final String? title;
  final Widget? centerWidget;

  const CustomAppBar({
    Key? key,
    this.title,
    this.centerWidget,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: kToolbarHeight,
      backgroundColor: Color(0xFF222831),
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
            icon: const Icon(Icons.logout),
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }


  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
