import 'package:flutter/material.dart';

class RequestInstallationPage extends StatefulWidget {
  const RequestInstallationPage({super.key});

  @override
  State<RequestInstallationPage> createState() => _RequestInstallationPageState();
}

class _RequestInstallationPageState extends State<RequestInstallationPage> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  void _submitInstallation() {
    String item = _itemController.text.trim();
    String location = _locationController.text.trim();

    if (item.isNotEmpty && location.isNotEmpty) {
      // Firebase logic goes here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Installation request sent for admin approval")),
      );

      _itemController.clear();
      _locationController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text("Request Installation", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: _itemController,
            decoration: const InputDecoration(labelText: "Item Name"),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(labelText: "Location for Installation"),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitInstallation,
            child: const Text("Send Request"),
          ),
        ],
      ),
    );
  }
}
