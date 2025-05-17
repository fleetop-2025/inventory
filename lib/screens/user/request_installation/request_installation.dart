import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RequestInstallationPage extends StatefulWidget {
  const RequestInstallationPage({super.key});

  @override
  State<RequestInstallationPage> createState() => _RequestInstallationPageState();
}

class _RequestInstallationPageState extends State<RequestInstallationPage> {
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _installationTypes = [];
  Map<String, dynamic>? _selectedInstallationType;

  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _imeiController = TextEditingController();
  final TextEditingController _sensorSerialController = TextEditingController();
  final TextEditingController _relaySerialController = TextEditingController();
  final TextEditingController _panicQuantityController = TextEditingController();
  final TextEditingController _simController = TextEditingController();
  final TextEditingController _vehicleController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _installedByController = TextEditingController();
  final TextEditingController _referredByController = TextEditingController();
  final TextEditingController _invoiceNumberController = TextEditingController();

  String? _tariffPlan;
  bool _keywordStatus = false;
  String? _customerExcelStatus;
  String? _calibrationFileStatus;
  String? _paymentStatus;

  @override
  void initState() {
    super.initState();
    _fetchInstallationTypes();
  }

  Future<void> _fetchInstallationTypes() async {
    final snapshot = await FirebaseFirestore.instance.collection('installation_types').get();
    setState(() {
      _installationTypes = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  List<String> _getCategories() {
    if (_selectedInstallationType == null || _selectedInstallationType!['categories'] == null) {
      return [];
    }
    return List<String>.from(_selectedInstallationType!['categories']);
  }

  void _clearFormFields() {
    _selectedInstallationType = null;
    _locationController.clear();
    _phoneController.clear();
    _imeiController.clear();
    _sensorSerialController.clear();
    _relaySerialController.clear();
    _panicQuantityController.clear();
    _simController.clear();
    _vehicleController.clear();
    _companyController.clear();
    _userIdController.clear();
    _installedByController.clear();
    _referredByController.clear();
    _invoiceNumberController.clear();
    _tariffPlan = null;
    _keywordStatus = false;
    _customerExcelStatus = null;
    _calibrationFileStatus = null;
    _paymentStatus = null;
  }

  void _submitInstallation() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _selectedInstallationType == null) return;

    final data = {
      'installation_type_id': _selectedInstallationType!['id'],
      'installation_type_name': _selectedInstallationType!['name'],
      'imei_number': _imeiController.text.trim(),
      'sensor_serial_number': _sensorSerialController.text.trim(),
      'relay_serial_number': _relaySerialController.text.trim(),
      'panic_quantity': int.tryParse(_panicQuantityController.text.trim()) ?? 0,
      'location': _locationController.text.trim(),
      'phone_number': _phoneController.text.trim(),
      'sim_number': _simController.text.trim(),
      'vehicle_number': _vehicleController.text.trim(),
      'company_name': _companyController.text.trim(),
      'user_id': _userIdController.text.trim(),
      'installed_by': _installedByController.text.trim(),
      'referred_by': _referredByController.text.trim(),
      'invoice_number': _invoiceNumberController.text.trim(),
      'tariff_plan': _tariffPlan,
      'keyword_status': _keywordStatus,
      'customer_excel_status': _customerExcelStatus,
      'calibration_file_status': _calibrationFileStatus,
      'payment_status': _paymentStatus,
      'requestedBy': uid,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('TemporaryInstallation').add(data);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Installation request sent for admin approval")),
    );

    setState(() {
      _formKey.currentState!.reset();
      _clearFormFields();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Installation')),
      body: _installationTypes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<Map<String, dynamic>>(
                value: _selectedInstallationType,
                decoration: const InputDecoration(labelText: "Installation Type"),
                items: _installationTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type['name'] ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedInstallationType = val;
                  });
                },
                validator: (val) => val == null ? 'Please select installation type' : null,
              ),
              const SizedBox(height: 10),
              ..._buildDynamicFields(),
              const Divider(),
              _buildTextField(_locationController, "Installation Location", validator: _required),
              _buildTextField(_phoneController, "Phone Number", keyboardType: TextInputType.phone, validator: _phoneValidator),
              _buildTextField(_simController, "SIM Number", keyboardType: TextInputType.phone, validator: _simValidator),
              _buildTextField(_vehicleController, "Vehicle Number", validator: _required),
              _buildTextField(_companyController, "Company Name", validator: _required),
              _buildTextField(_userIdController, "User ID", validator: _required),
              _buildTextField(_installedByController, "Installed By", validator: _required),
              _buildTextField(_referredByController, "Referred By"),
              _buildTextField(_invoiceNumberController, "Estimation/Invoice Number"),
              DropdownButtonFormField<String>(
                value: _tariffPlan,
                decoration: const InputDecoration(labelText: "Tariff Plan"),
                items: ['Yearly', 'Half-Yearly', 'Quarterly', 'Monthly']
                    .map((plan) => DropdownMenuItem(value: plan, child: Text(plan)))
                    .toList(),
                onChanged: (val) => setState(() => _tariffPlan = val),
                validator: (val) => val == null ? 'Select a plan' : null,
              ),
              CheckboxListTile(
                value: _keywordStatus,
                onChanged: (val) => setState(() => _keywordStatus = val ?? false),
                title: const Text("Keyword Status"),
              ),
              DropdownButtonFormField<String>(
                value: _customerExcelStatus,
                decoration: const InputDecoration(labelText: "Customer Excel Updation"),
                items: ['Pending', 'Done']
                    .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                    .toList(),
                onChanged: (val) => setState(() => _customerExcelStatus = val),
                validator: (val) => val == null ? 'Select status' : null,
              ),
              DropdownButtonFormField<String>(
                value: _calibrationFileStatus,
                decoration: const InputDecoration(labelText: "Calibration File Addition"),
                items: ['Pending', 'Uploaded']
                    .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                    .toList(),
                onChanged: (val) => setState(() => _calibrationFileStatus = val),
                validator: (val) => val == null ? 'Select status' : null,
              ),
              DropdownButtonFormField<String>(
                value: _paymentStatus,
                decoration: const InputDecoration(labelText: "Payment Status"),
                items: ['Paid', 'Unpaid']
                    .map((val) => DropdownMenuItem(value: val.toLowerCase(), child: Text(val)))
                    .toList(),
                onChanged: (val) => setState(() => _paymentStatus = val),
                validator: (val) => val == null ? 'Select payment status' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitInstallation,
                child: const Text("Send Request"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDynamicFields() {
    final categories = _getCategories();
    final fields = <Widget>[];

    if (categories.contains('GPS')) {
      fields.add(_buildTextField(_imeiController, "IMEI Number",keyboardType: TextInputType.phone, validator: (val) {
        if (val == null || val.length < 15) return "Enter valid IMEI";
        return null;
      }));
    }

    if (categories.contains('Sensors')) {
      fields.add(_buildTextField(_sensorSerialController, "Sensor Serial Number",keyboardType: TextInputType.phone, validator: _required));
    }

    if (categories.contains('Relays')) {
      fields.add(_buildTextField(_relaySerialController, "Relay Serial Number",keyboardType: TextInputType.phone, validator: _required));
    }

    if (categories.contains('Panic Buttons')) {
      fields.add(_buildTextField(_panicQuantityController, "Panic Button Quantity",
          keyboardType: TextInputType.number, validator: (val) {
            if (val == null || int.tryParse(val) == null || int.parse(val) <= 0) {
              return "Enter valid quantity";
            }
            return null;
          }));
    }

    return fields;
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(labelText: label),
        validator: validator,
      ),
    );
  }

  String? _required(String? val) => (val == null || val.isEmpty) ? "This field is required" : null;

  String? _phoneValidator(String? val) {
    if (val == null || val.length < 10) return "Enter valid phone number";
    return null;
  }
  String? _simValidator(String? val){
    if(val == null || val.length < 13) return "Sim Number should be of 13 digits";
    return null;
  }
}
