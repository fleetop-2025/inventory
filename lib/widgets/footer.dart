// widgets/footer.dart

import 'package:flutter/material.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.grey[200],
      child: const Text(
        '© 2025 Fleetop Technologies. All rights reserved.',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}
