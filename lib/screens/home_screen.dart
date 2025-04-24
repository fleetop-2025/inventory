import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory App'),
      ),
      body: const Center(
        child: Text(
          'Welcome to Inventory!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
