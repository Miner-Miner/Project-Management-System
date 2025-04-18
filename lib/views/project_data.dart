import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:pms/util/database_util.dart';

class AddProjectDataPage extends StatefulWidget {
  @override
  _AddProjectDataPageState createState() => _AddProjectDataPageState();
}

class _AddProjectDataPageState extends State<AddProjectDataPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();

  List<Map<String, dynamic>> _projectList = [];
  int? _selectedProjectId;
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  void _loadProjects() {
    _projectList = DatabaseHelper().getAllProjects(); // Replace with your method
    setState(() {}); // Refresh UI
  }

  @override
  Widget build(BuildContext context) {
    log(_projectList.toString());
    return Scaffold(
      appBar: AppBar(title: Text('Add Project Data')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Project Dropdown
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: 'Project', border: OutlineInputBorder()),
                items: _projectList.map((p) => DropdownMenuItem<int>(
                  value: p['id'],
                  child: Text(p['project_name']),
                )).toList(),
                value: _selectedProjectId,
                validator: (v) => v == null ? 'Please select project' : null,
                onChanged: (id) => setState(() => _selectedProjectId = id),
              ),
              SizedBox(height: 16),

              // Date Picker
              ListTile(
                title: Text(_selectedDate == null
                    ? 'Select Date'
                    : 'Date: $_selectedDate'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked.toIso8601String().split('T')[0];
                    });
                  }
                },
              ),
              SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              SizedBox(height: 16),

              // Cost
              TextFormField(
                controller: _costController,
                decoration: InputDecoration(labelText: 'Cost', border: OutlineInputBorder()),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter cost';
                  final cost = double.tryParse(value);
                  if (cost == null || cost < 0) return 'Enter a valid number';
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Save Data'),
                style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'project_id': _selectedProjectId,
      'date': _selectedDate,
      'description': _descriptionController.text,
      'cost': double.parse(_costController.text),
    };

    print(data.toString());
    await DatabaseHelper().insertData(projectId: _selectedProjectId!,description: _descriptionController.text,cost: double.parse(_costController.text) , date: _selectedDate!); // Implement this method

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Project data added')));

    Navigator.pop(context, 'refresh');
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _costController.dispose();
    super.dispose();
  }
}

class ProjectDataListPage extends StatefulWidget {
  const ProjectDataListPage({super.key});

  @override
  State<ProjectDataListPage> createState() => _ProjectDataListPageState();
}

class _ProjectDataListPageState extends State<ProjectDataListPage> {
  int no = 0;
  int? _selectedProjectFilterId = null;

  @override
  void initState() {
    super.initState();    // load initial table
  }

  @override
  Widget build(BuildContext context) {
    no = 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Project Data List')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ─── Project Filter ─────────────────────────────────────────────
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: 'Filter by Project',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                DropdownMenuItem<int>(
                  value: null,
                  child: Text('All'),
                ),
                ...DatabaseHelper().getAllProjects().map((p) => DropdownMenuItem<int>(
                      value: p['id'],
                      child: Text(p['project_name']),
                    )),
              ],
              value: _selectedProjectFilterId,
              onChanged: (projId) {
                setState(() => _selectedProjectFilterId = projId);
              },
            ),
            const SizedBox(height: 16),

            // ─── Data Table ─────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('No')),
                    DataColumn(label: Text('Project')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Description')),
                    DataColumn(label: Text('Cost')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: DatabaseHelper().getAllDataWhere(_selectedProjectFilterId).map((data) {
                    no++;
                    log(data.toString());
                    return DataRow(cells: [
                      DataCell(Text(no.toString())),
                      DataCell(Text(DatabaseHelper().getRecordByIdAndGetColumn('project', data['project_id'], 'project_name'))),
                      DataCell(Text(data['date'] ?? '—')),
                      DataCell(Text(data['description'] ?? '')),
                      DataCell(Text(data['cost'].toString())),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditProjectDataPage(data['id']),
                                ),
                              );
                              if (result == 'refresh') setState(() {});
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Confirmation'),
                                  content: Text(
                                    'Delete entry for "${data['project_id']}" on ${data['date']}?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Yes'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('No'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await DatabaseHelper().deleteData(data['id']);
                                setState(() {});;
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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddProjectDataPage()),
          );
          if (result == 'refresh') {
            _selectedProjectFilterId=null;
            setState(() {
            });
          };
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class EditProjectDataPage extends StatefulWidget {
  final id;
  EditProjectDataPage(this.id);

  @override
  State<EditProjectDataPage> createState() => _EditProjectDataPageState(id);
}

class _EditProjectDataPageState extends State<EditProjectDataPage> {
  final id;
  _EditProjectDataPageState(this.id);
  
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();

  List<Map<String, dynamic>> _projectList = [];
  int? _selectedProjectId;
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadProjects();
    var _temp = DatabaseHelper().getRecordById('data', id);
    _descriptionController.text = _temp!['description'];
    _costController.text = _temp!['cost'].toString();
    _selectedDate = _temp!['date'];
  }

  void _loadProjects() {
    _projectList = DatabaseHelper().getAllProjects(); // Replace with your method
    setState(() {}); // Refresh UI
  }

  @override
  Widget build(BuildContext context) {
    log(_projectList.toString());
    return Scaffold(
      appBar: AppBar(title: Text('Add Project Data')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Project Dropdown
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: 'Project', border: OutlineInputBorder()),
                items: _projectList.map((p) => DropdownMenuItem<int>(
                  value: p['id'],
                  child: Text(p['project_name']),
                )).toList(),
                value: _selectedProjectId,
                validator: (v) => v == null ? 'Please select project' : null,
                onChanged: (id) => setState(() => _selectedProjectId = id),
              ),
              SizedBox(height: 16),

              // Date Picker
              SingleChildScrollView(
                child: ListTile(
                  title: Text(_selectedDate == null
                      ? 'Select Date'
                      : 'Date: $_selectedDate'),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked.toIso8601String().split('T')[0];
                      });
                    }
                  },
                ),
              ),
              SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              SizedBox(height: 16),

              // Cost
              TextFormField(
                controller: _costController,
                decoration: InputDecoration(labelText: 'Cost', border: OutlineInputBorder()),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter cost';
                  final cost = double.tryParse(value);
                  if (cost == null || cost < 0) return 'Enter a valid number';
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Save Data'),
                style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'project_id': _selectedProjectId,
      'date': _selectedDate,
      'description': _descriptionController.text,
      'cost': double.parse(_costController.text),
    };

    await DatabaseHelper().updateData(id,projectId: _selectedProjectId!,description: _descriptionController.text,cost: double.parse(_costController.text) , date: _selectedDate!); // Implement this method

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Project data updated')));
    
    Navigator.pop(context, 'refresh');
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _costController.dispose();
    super.dispose();
  }
}