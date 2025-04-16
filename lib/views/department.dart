import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:pms/util/database_util.dart';
import 'package:pms/views/addon/alertdialog.dart';

class AddDepartmentPage extends StatefulWidget {
  @override
  _AddDepartmentPageState createState() => _AddDepartmentPageState();
}

class _AddDepartmentPageState extends State<AddDepartmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _headController = TextEditingController();
  String? _selectedHQ;

  late List<Map<String,dynamic>> hq;
  late List<String> _hq;
  late List<int> _hqID;

  @override
  void initState() {
    super.initState();
    hq = DatabaseHelper().getAllHQ();
  }

  @override
  Widget build(BuildContext context) {
    _hq = [];
    _hqID = [];
    for (int i=0; i<hq.length; i++){
      Map<String,dynamic> _temp = hq[i];
      _hq.add(_temp['location']);
      _hqID.add(_temp['id']);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Department'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _submitForm,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Department Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter department name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _headController,
                decoration: InputDecoration(
                  labelText: 'Department Head',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter department head';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'HQ',
                  border: OutlineInputBorder(),
                ),
                value: _selectedHQ,
                items: _hq.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedHQ = newValue;
                  });
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Save Department'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() async{
    if (_formKey.currentState!.validate()) {
      // Save the department logic here
      final newDepartment = {
        'name': _nameController.text,
        'head': _headController.text,
        'location': _selectedHQ,
      };
      
      DatabaseHelper().insertDepartment(_nameController.text,_headController.text, _hqID[_hq.indexOf("$_selectedHQ")]);

      // Typically you would save to database here
      print('New Department: $newDepartment');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Department added successfully')),
      );
      bool confirm = await AddAnother(context, "Department", [_nameController,_headController]);
      if (confirm == true) {
        log('true');
      }
      else {Navigator.pop(context,'refresh');}
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _headController.dispose();
    super.dispose();
  }
}

class DepartmentListPage extends StatefulWidget {
  const DepartmentListPage({super.key});

  @override
  State<DepartmentListPage> createState() => _DepartmentListPageState();
}

class _DepartmentListPageState extends State<DepartmentListPage> {
  late List<Map<String, dynamic>> departments;
  late List<Map<String, dynamic>> employeeCount;

  @override
  void initState() {
    super.initState();
    departments = DatabaseHelper().getAllDepartments();
    employeeCount = DatabaseHelper().getEmployeeCountByDepartment();
    for (var entry in employeeCount) {
      print('Department ${entry['department_id']} has ${entry['count']} employees.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: MediaQuery.sizeOf(context).width,
        height: MediaQuery.sizeOf(context).height,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columns: [
              DataColumn(label: Text('Department Name')),
              DataColumn(label: Text('Department Head')),
              DataColumn(label: Text('Employees Count')),
              DataColumn(label: Text('Location')),
              DataColumn(label: Text('Actions')),
            ],
            rows: DatabaseHelper().getAllDepartments().map((dept) {
              return DataRow(cells: [
                DataCell(Text(dept['department_name'])),
                DataCell(Text(dept['department_head_name'])),
                DataCell(Text(DatabaseHelper().getEmployeeCountForDepartment(dept['id']).toString())),
                DataCell(Text(DatabaseHelper().getRecordByIdAndGetColumn("hq", dept['hq_id'],"location").toString())),
                DataCell(Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () async {
                        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditDepartmentPage(dept['id'])));
                        if (result == 'refresh') {
                          setState(() {
                          });
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
                            content: Text('Do you really want to delete ${dept['department_name']}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('No'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('Yes'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await DatabaseHelper().deleteHQ(dept['id']);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AddDepartmentPage()));
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class EditDepartmentPage extends StatefulWidget {
  final int id;
  EditDepartmentPage(this.id);

  @override
  State<EditDepartmentPage> createState() => _EditDepartmentPageState(id);
}

class _EditDepartmentPageState extends State<EditDepartmentPage> {
   final int id;
  _EditDepartmentPageState(this.id);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _headController = TextEditingController();
  String? _selectedHQ;

  late List<Map<String,dynamic>> hq;
  late List<String> _hq;
  late List<int> _hqID;
  late Map<String,dynamic> current_dept;

  @override
  void initState() {
    super.initState();
    hq = DatabaseHelper().getAllHQ();
    current_dept = DatabaseHelper().getRecordById('department', id)!;
    _nameController.text = current_dept['department_name'];
    _headController.text = current_dept['department_head_name'];
  }

  @override
  Widget build(BuildContext context) {
    _hq = [];
    _hqID = [];
    for (int i=0; i<hq.length; i++){
      Map<String,dynamic> _temp = hq[i];
      _hq.add(_temp['location']);
      _hqID.add(_temp['id']);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Update Department'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _submitForm,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Department Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter department name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _headController,
                decoration: InputDecoration(
                  labelText: 'Department Head',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter department head';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'HQ',
                  border: OutlineInputBorder(),
                ),
                value: _selectedHQ,
                items: _hq.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedHQ = newValue;
                  });
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Save Department'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
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
        final hqId = _hqID[_hq.indexOf(_selectedHQ!)];
        DatabaseHelper().updateDepartment(
          id,
          departmentName: _nameController.text,
          departmentHeadName: _headController.text,
          hqId: hqId,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Department changed successfully')),
        );
        // Finally pop the edit page with a result
        Navigator.pop(context, 'refresh');
      }
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    _headController.dispose();
    super.dispose();
  }
}

