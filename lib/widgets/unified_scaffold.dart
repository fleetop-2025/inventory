import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'collapsible_sidebar.dart';

class UnifiedScaffold extends StatefulWidget {
  final String initialPage;
  final Widget Function(String page) pageBuilder;

  const UnifiedScaffold({
    super.key,
    required this.initialPage,
    required this.pageBuilder,
  });

  @override
  State<UnifiedScaffold> createState() => _UnifiedScaffoldState();
}

class _UnifiedScaffoldState extends State<UnifiedScaffold> {
  String _selectedPage = '';

  @override
  void initState() {
    super.initState();
    _selectedPage = widget.initialPage;
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedPage),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          )
        ],
      ),
      body: Row(
        children: [
          CollapsibleSidebar(
            selectedItem: _selectedPage,
            onItemSelected: (title) {
              setState(() => _selectedPage = title);
            },
          ),
          Expanded(child: widget.pageBuilder(_selectedPage)),
        ],
      ),
    );
  }
}
