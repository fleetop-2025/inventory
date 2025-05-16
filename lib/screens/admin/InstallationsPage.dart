import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InstallationsPage extends StatefulWidget {
  @override
  _InstallationsPageState createState() => _InstallationsPageState();
}

class _InstallationsPageState extends State<InstallationsPage> {
  String _selectedStatus = 'All';
  String _sortField = 'timestamp';
  bool _isAscending = false;

  // Search filters
  String invoiceSearch = '';
  String imeiSearch = '';
  String companySearch = '';
  String tariffSearch = '';
  String keywordStatusSearch = '';
  String calibrationStatusSearch = '';
  String customerExcelStatusSearch = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Installations")),
      body: Column(
        children: [
          _buildFilterOptions(),
          _buildSearchFields(),
          Expanded(child: _buildInstallationsList()),
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          DropdownButton<String>(
            value: _selectedStatus,
            items: ['All', 'Pending', 'Approved', 'Rejected']
                .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                .toList(),
            onChanged: (val) => setState(() => _selectedStatus = val!),
          ),
          const SizedBox(width: 20),
          DropdownButton<String>(
            value: _sortField,
            items: ['timestamp', 'panic_quantity', 'requestedBy']
                .map((field) => DropdownMenuItem(value: field, child: Text("Sort by $field")))
                .toList(),
            onChanged: (val) => setState(() => _sortField = val!),
          ),
          IconButton(
            icon: Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward),
            onPressed: () => setState(() => _isAscending = !_isAscending),
          )
        ],
      ),
    );
  }

  Widget _buildSearchFields() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _buildSearchBox("Invoice No", (val) => setState(() => invoiceSearch = val)),
          _buildSearchBox("IMEI No", (val) => setState(() => imeiSearch = val)),
          _buildSearchBox("Company Name", (val) => setState(() => companySearch = val)),
          _buildSearchBox("Tariff Plan", (val) => setState(() => tariffSearch = val)),
          _buildSearchBox("Keyword Status", (val) => setState(() => keywordStatusSearch = val)),
          _buildSearchBox("Calibration File Status", (val) => setState(() => calibrationStatusSearch = val)),
          _buildSearchBox("Customer Excel Status", (val) => setState(() => customerExcelStatusSearch = val)),
        ],
      ),
    );
  }

  Widget _buildSearchBox(String hint, Function(String) onChanged) {
    return SizedBox(
      width: 180,
      child: TextField(
        decoration: InputDecoration(
          labelText: hint,
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildInstallationsList() {
    Query query = FirebaseFirestore.instance.collection('TemporaryInstallation');
    if (_selectedStatus != 'All') {
      query = query.where('status', isEqualTo: _selectedStatus.toLowerCase());
    }
    query = query.orderBy(_sortField, descending: !_isAscending);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;

        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['invoice_number'] ?? '').toString().toLowerCase().contains(invoiceSearch.toLowerCase()) &&
              (data['imei_number'] ?? '').toString().toLowerCase().contains(imeiSearch.toLowerCase()) &&
              (data['company_name'] ?? '').toString().toLowerCase().contains(companySearch.toLowerCase()) &&
              (data['tariff_plan'] ?? '').toString().toLowerCase().contains(tariffSearch.toLowerCase()) &&
              (data['keyword_status'] ?? '').toString().toLowerCase().contains(keywordStatusSearch.toLowerCase()) &&
              (data['calibration_file_status'] ?? '').toString().toLowerCase().contains(calibrationStatusSearch.toLowerCase()) &&
              (data['customer_excel_status'] ?? '').toString().toLowerCase().contains(customerExcelStatusSearch.toLowerCase());
        }).toList();

        return ListView.builder(
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final data = filteredDocs[index].data() as Map<String, dynamic>;
            final userId = data['requestedBy'];
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
              builder: (context, snapshot) {
                String userEmail = 'Unknown';
                if (snapshot.hasData && snapshot.data!.exists) {
                  userEmail = snapshot.data!.get('email') ?? 'Unknown';
                }
                return _buildInstallationCard(data, userEmail);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildInstallationCard(Map<String, dynamic> data, String userEmail) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text("Requested by: $userEmail"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Installation Type: ${data['installation_type_name']}"),
            Text("Panic Button Quantity: ${data['panic_quantity']}"),
            Text("IMEI No: ${data['imei_number']}"),
            Text("Relay Serial No: ${data['relay_serial_number']}"),
            Text("Sensor Serial No: ${data['sensor_serial_number']}"),
            Text("Location: ${data['location']}"),
            Text("Company Name: ${data['company_name']}"),
            Text("Phone Number: ${data['phone_number']}"),
            Text("SIM Number: ${data['sim_number']}"),
            Text("Tariff Plan: ${data['tariff_plan']}"),
            Text("User Id: ${data['user_id']}"),
            Text("Vehicle No: ${data['vehicle_number']}"),
            Text("Referred By: ${data['referred_by']}"),
            Text("Installed By: ${data['installed_by']}"),
            Text("Inv/Est No: ${data['invoice_number']}"),
            Text("Keyword Status: ${data['keyword_status']}"),
            Text("Calibration File Status: ${data['calibration_file_status']}"),
            Text("Customer Excel Status: ${data['customer_excel_status']}"),
            Text("Status: ${data['status']}"),
            Text("Requested At: ${data['timestamp'].toDate()}"),
          ],
        ),
      ),
    );
  }
}
