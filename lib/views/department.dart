import 'package:flutter/material.dart';

class AddDepartmentPage extends StatefulWidget {
  @override
  _AddDepartmentPageState createState() => _AddDepartmentPageState();
}

class _AddDepartmentPageState extends State<AddDepartmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _headController = TextEditingController();
  String _location = 'Headquarters';

  @override
  Widget build(BuildContext context) {
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
                value: _location,
                decoration: InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                items: ['Headquarters', 'Branch 1', 'Branch 2', 'Remote']
                    .map((location) => DropdownMenuItem(
                          value: location,
                          child: Text(location),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _location = value!;
                  });
                },
              ),
              SizedBox(height: 24),
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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Save the department logic here
      final newDepartment = {
        'name': _nameController.text,
        'head': _headController.text,
        'location': _location,
      };
      
      // Typically you would save to database here
      print('New Department: $newDepartment');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Department added successfully')),
      );
      
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _headController.dispose();
    super.dispose();
  }
}

class DepartmentListPage extends StatelessWidget {
  final List<Map<String, dynamic>> departments = [
    {'name': 'IT', 'head': 'John Doe', 'employees': 15},
    {'name': 'HR', 'head': 'Jane Smith', 'employees': 8},
    {'name': 'Finance', 'head': 'Robert Johnson', 'employees': 12},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text('Department Name')),
            DataColumn(label: Text('Department Head')),
            DataColumn(label: Text('Employees Count')),
            DataColumn(label: Text('Actions')),
          ],
          rows: departments.map((dept) {
            return DataRow(cells: [
              DataCell(Text(dept['name'])),
              DataCell(Text(dept['head'])),
              DataCell(Text(dept['employees'].toString())),
              DataCell(Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {},
                  ),
                ],
              )),
            ]);
          }).toList(),
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
