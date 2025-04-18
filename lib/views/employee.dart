import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:pms/util/database_util.dart';
import 'package:pms/views/addon/alertdialog.dart';

class AddEmployeePage extends StatefulWidget {
  @override
  _AddEmployeePageState createState() => _AddEmployeePageState();
}

class _AddEmployeePageState extends State<AddEmployeePage> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _phoneController    = TextEditingController();
  final _positionController = TextEditingController();
  final _skillController = TextEditingController();
  final _addressController = TextEditingController();

  String? _hireDate;

  // HQ & Department
  List<Map<String, dynamic>> _hqList = [];
  List<Map<String, dynamic>> _deptList = [];
  int? _selectedHqId;
  int? _selectedDeptId;

  @override
  void initState() {
    super.initState();
    _loadHqs();
  }

  void _loadHqs() {
    _hqList = DatabaseHelper().getAllHQ();
  }

  Future<void> _loadDepartments(int hqId) async {
    _deptList = await DatabaseHelper().getDepartmentsByHq(hqId);
  }

  @override
  Widget build(BuildContext context) {
    log(_hqList.toString());
    return Scaffold(
      appBar: AppBar(title: Text('Add New Employee')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Full Name
              _buildTextField(_nameController, 'Full Name', (v) => v!.isEmpty ? 'Please enter name' : null),
              SizedBox(height: 16),

              // Email
              _buildTextField(
                _emailController,
                'Email',
                (v) {
                  if (v!.isEmpty) return 'Please enter email';
                  if (!v.contains('@')) return 'Please enter a valid email';
                  return null;
                },
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),

              // Phone Number
              _buildTextField(_phoneController, 'Phone Number', null, keyboardType: TextInputType.phone),
              SizedBox(height: 16),

              // Address as Text Field
              _buildTextField(_addressController, 'Address', (v) => v!.isEmpty ? 'Please enter position' : null),
              SizedBox(height: 16),

              // Position as Text Field
              _buildTextField(_positionController, 'Position', (v) => v!.isEmpty ? 'Please enter position' : null),
              SizedBox(height: 16),

              // Skill as Text Field
              _buildTextField(_skillController, 'Skill', (v) => v!.isEmpty ? 'Please enter skill' : null),
              SizedBox(height: 16),

              // HQ Dropdown
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: 'Headquarters',
                  border: OutlineInputBorder(),
                ),
                items: _hqList.map((hq) => DropdownMenuItem<int>(
                  value: hq['id'],
                  child: Text(hq['location']),
                )).toList(),
                value: _selectedHqId,
                validator: (v) => v == null ? 'Please select HQ' : null,
                onChanged: (hqId) {
                  setState(() {
                    _selectedHqId = hqId;
                    _selectedDeptId = null;
                    _deptList = [];
                  });
                  if (hqId != null) {
                    _loadDepartments(hqId);
                  }
                },
              ),
              SizedBox(height: 16),

              // Department Dropdown (shown after HQ selected)
              if (_selectedHqId != null) ...[
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                  ),
                  items: _deptList.map((dept) => DropdownMenuItem<int>(
                    value: dept['id'],
                    child: Text(dept['department_name']),
                  )).toList(),
                  value: _selectedDeptId,
                  validator: (v) => v == null ? 'Please select department' : null,
                  onChanged: (deptId) {
                    setState(() => _selectedDeptId = deptId);
                  },
                ),
                SizedBox(height: 16),
              ],

              // Hire Date Picker
              ListTile(
                title: Text(
                  _hireDate == null
                    ? 'Select Hire Date'
                    : 'Hire Date: ${_hireDate}',
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _hireDate = picked.toLocal().toIso8601String().split('T')[0]);
                },
              ),
              SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Save Employee'),
                style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String? Function(String?)? validator, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
      validator: validator,
      keyboardType: keyboardType,
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    DatabaseHelper().insertEmployee(
      fullName: _nameController.text,
      email: _emailController.text,
      phoneNumber: _phoneController.text,
      address: _addressController.text,
      hqId: _selectedHqId!,
      departmentId: _selectedDeptId!,
      position: _positionController.text,
      skill: _skillController.text,
      hireDate: _hireDate,
    );

    bool result = await AddAnother(context, 'Employee', [_nameController,_emailController,_phoneController,_positionController,_addressController,_skillController]);
    if(result != true){
      Navigator.pop(context,'refresh');
    }
    else {
      _selectedHqId = null;
      _selectedDeptId = null;
      _hireDate = null;
      setState(() {
        _hqList = [];
        _deptList = [];
        _hqList = DatabaseHelper().getAllHQ();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    super.dispose();
  }
}

class EmployeeListPage extends StatefulWidget {
  const EmployeeListPage({super.key});

  @override
  State<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  int no = 0;

  @override
  Widget build(BuildContext context) {
    no = 0;
    return Scaffold(
      body: SizedBox(
        width: MediaQuery.sizeOf(context).width,
        height: MediaQuery.sizeOf(context).height,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              columns: [
                DataColumn(label: Text('No')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Phone')),
                DataColumn(label: Text('Address')),
                DataColumn(label: Text('Headquarter')),
                DataColumn(label: Text('Department')),
                DataColumn(label: Text('Position')),
                DataColumn(label: Text('Skill')),
                DataColumn(label: Text('Hire Date')),
                DataColumn(label: Text('Actions')),
              ],
              rows: DatabaseHelper().getAllEmployees().map((emp) {
                no++;
                return DataRow(cells: [
                  DataCell(Text(no.toString())),
                  DataCell(Text(emp['full_name'] ?? '-')),
                  DataCell(Text(emp['email'] ?? '-')),
                  DataCell(Text(emp['phone_number'] ?? '-')),
                  DataCell(Text(emp['address'] ?? '-')),
                  DataCell(Text(emp['hq_id'].toString())),
                  DataCell(Text(emp['department_id'].toString())),
                  DataCell(Text(emp['position'] ?? '-')),
                  DataCell(Text(emp['skill'] ?? '-')),
                  DataCell(Text(emp['hire_date'] ?? '-')),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          String result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EditEmployeePage(emp['id'])),
                          );
                          if (result == 'refresh') {
                            setState(() {});
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Delete Confirmation'),
                              content: Text('Do you really want to delete ${emp['full_name']}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text('Yes'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text('No'),
                                ),
                              ],
                            ),
                          );
          
                          if (confirm == true) {
                            DatabaseHelper().deleteEmployee(emp['id']);
                            setState(() {});
                          }
                        },
                      ),
                    ],
                  )),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          String result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddEmployeePage()),
          );
          if (result == 'refresh') {
            setState(() {});
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}


class EditEmployeePage extends StatefulWidget {
  final int id;
  EditEmployeePage(this.id);

  @override
  State<EditEmployeePage> createState() => _EditEmployeePageState(id);
}

class _EditEmployeePageState extends State<EditEmployeePage> {
  final int id;
  _EditEmployeePageState(this.id);

  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _phoneController    = TextEditingController();
  final _positionController = TextEditingController();
  final _skillController = TextEditingController();
  final _addressController = TextEditingController();

  String? _hireDate;

  // HQ & Department
  List<Map<String, dynamic>> _hqList = [];
  List<Map<String, dynamic>> _deptList = [];
  int? _selectedHqId;
  int? _selectedDeptId;

  @override
  void initState() {
    super.initState();
    _loadHqs();
  }

  void _loadHqs() {
    _hqList = DatabaseHelper().getAllHQ();
  }

  Future<void> _loadDepartments(int hqId) async {
    _deptList = await DatabaseHelper().getDepartmentsByHq(hqId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add New Employee')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Full Name
              _buildTextField(_nameController, 'Full Name', (v) => v!.isEmpty ? 'Please enter name' : null),
              SizedBox(height: 16),

              // Email
              _buildTextField(
                _emailController,
                'Email',
                (v) {
                  if (v!.isEmpty) return 'Please enter email';
                  if (!v.contains('@')) return 'Please enter a valid email';
                  return null;
                },
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),

              // Phone Number
              _buildTextField(_phoneController, 'Phone Number', null, keyboardType: TextInputType.phone),
              SizedBox(height: 16),

              // Address as Text Field
              _buildTextField(_addressController, 'Address', (v) => v!.isEmpty ? 'Please enter position' : null),
              SizedBox(height: 16),

              // Position as Text Field
              _buildTextField(_positionController, 'Position', (v) => v!.isEmpty ? 'Please enter position' : null),
              SizedBox(height: 16),

              // Skill as Text Field
              _buildTextField(_skillController, 'Skill', (v) => v!.isEmpty ? 'Please enter skill' : null),
              SizedBox(height: 16),

              // HQ Dropdown
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: 'Headquarters',
                  border: OutlineInputBorder(),
                ),
                items: _hqList.map((hq) => DropdownMenuItem<int>(
                  value: hq['id'],
                  child: Text(hq['location']),
                )).toList(),
                value: _selectedHqId,
                validator: (v) => v == null ? 'Please select HQ' : null,
                onChanged: (hqId) {
                  setState(() {
                    _selectedHqId = hqId;
                    _selectedDeptId = null;
                    _deptList = [];
                  });
                  if (hqId != null) {
                    _loadDepartments(hqId);
                  }
                },
              ),
              SizedBox(height: 16),

              // Department Dropdown (shown after HQ selected)
              if (_selectedHqId != null) ...[
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                  ),
                  items: _deptList.map((dept) => DropdownMenuItem<int>(
                    value: dept['id'],
                    child: Text(dept['department_name']),
                  )).toList(),
                  value: _selectedDeptId,
                  validator: (v) => v == null ? 'Please select department' : null,
                  onChanged: (deptId) {
                    setState(() => _selectedDeptId = deptId);
                  },
                ),
                SizedBox(height: 16),
              ],

              // Hire Date Picker
              ListTile(
                title: Text(
                  _hireDate == null
                    ? 'Select Hire Date'
                    : 'Hire Date: ${_hireDate}',
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _hireDate = picked.toLocal().toIso8601String().split('T')[0]);
                },
              ),
              SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Save Employee'),
                style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String? Function(String?)? validator, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
      validator: validator,
      keyboardType: keyboardType,
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Ask for confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Do you want to update?"),
        content: Text("Are you sure you want to update to ${_nameController.text}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Yes"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("No")
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Update department in the database
      
      DatabaseHelper().updateEmployee(
        id,
        fullName: _nameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        address: _addressController.text,
        hqId: _selectedHqId!,
        departmentId: _selectedDeptId!,
        position: _positionController.text,
        skill: _skillController.text,
        hireDate: _hireDate,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Department changed successfully')),
      );
      // Finally pop the edit page with a result
      Navigator.pop(context, 'refresh');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    super.dispose();
  }
}
