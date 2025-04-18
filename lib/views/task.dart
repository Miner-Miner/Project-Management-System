
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:pms/util/database_util.dart';
import 'package:pms/views/addon/alertdialog.dart';

class AddTaskPage extends StatefulWidget {
  @override
  _AddTaskPageState createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();

  // Dropdown & Date
  List<Map<String, dynamic>> _projectList = [];
  List<Map<String, dynamic>> _empList = [];
  int? _selectedProjectId;
  int? _selectedEmpId;
  String? _priority;
  String? _status;
  String? _startDate;
  String? _dueDate;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  void _loadProjects() {
    _projectList = DatabaseHelper().getAllProjects();
  }

  Future<void> _loadEmployees(int projectId) async {
    _empList = await DatabaseHelper().getEmployeesByProject(projectId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add New Task')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_titleController, 'Task Title', (v) => v!.isEmpty ? 'Please enter title' : null),
              SizedBox(height: 16),

              _buildTextField(_descriptionController, 'Description', null, maxLines: 3),
              SizedBox(height: 16),
              
              _buildTextField(_budgetController, 'Budget', (v) => v!.isEmpty ? 'Please enter budget' : null),
              SizedBox(height: 16),

              // Project Dropdown
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: 'Project', border: OutlineInputBorder()),
                items: _projectList.map((p) => DropdownMenuItem<int>(
                  value: p['id'],
                  child: Text(p['project_name']),
                )).toList(),
                value: _selectedProjectId,
                validator: (v) => v == null ? 'Please select project' : null,
                onChanged: (id) {
                  setState(() {
                    _selectedProjectId = id;
                    _selectedEmpId = null;
                    _empList = [];
                  });
                  if (id != null) _loadEmployees(id);
                },
              ),
              SizedBox(height: 16),

              // Assigned To Dropdown (after project)
              if (_selectedProjectId != null) ...[
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(labelText: 'Assigned To', border: OutlineInputBorder()),
                  items: _empList.map((e) => DropdownMenuItem<int>(
                    value: e['id'],
                    child: Text(e['full_name']),
                  )).toList(),
                  value: _selectedEmpId,
                  validator: (v) => v == null ? 'Please select employee' : null,
                  onChanged: (id) => setState(() => _selectedEmpId = id),
                ),
                SizedBox(height: 16),
              ],

              // Priority
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                items: ['High', 'Medium', 'Low']
                    .map((p) => DropdownMenuItem<String>(value: p, child: Text(p))).toList(),
                value: _priority,
                validator: (v) => v == null ? 'Please select priority' : null,
                onChanged: (p) => setState(() => _priority = p),
              ),
              SizedBox(height: 16),

              // Status
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                items: ['Pending', 'Doing', 'Done', 'Completed']
                    .map((s) => DropdownMenuItem<String>(value: s, child: Text(s))).toList(),
                value: _status,
                validator: (v) => v == null ? 'Please select status' : null,
                onChanged: (s) => setState(() => _status = s),
              ),
              SizedBox(height: 16),

              // Start Date Picker
              ListTile(
                title: Text(_startDate == null
                    ? 'Select Start Date'
                    : 'Start Date: $_startDate'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _startDate = picked.toIso8601String().split('T')[0]);
                },
              ),
              SizedBox(height: 16),

              // Due Date Picker
              ListTile(
                title: Text(_dueDate == null
                    ? 'Select Due Date'
                    : 'Due Date: $_dueDate'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final initial = _startDate != null ? DateTime.parse(_startDate!) : DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: initial,
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _dueDate = picked.toIso8601String().split('T')[0]);
                },
              ),
              SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Save Task'),
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
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    await DatabaseHelper().insertTask(
      taskTitle: _titleController.text,
      description: _descriptionController.text,
      budget: double.parse(_budgetController.text),
      projectId: _selectedProjectId!,
      assignedTo: _selectedEmpId!,
      priority: _priority!,
      status: _status,
      taskStartDate: _startDate,
      taskEndDate: _dueDate,
    );

    bool again = await AddAnother(
      context,
      'Task',
      [_titleController, _descriptionController],
    );

    if (!again) {
      Navigator.pop(context, 'refresh');
    } else {
      setState(() {
        _selectedProjectId = null;
        _selectedEmpId = null;
        _priority = null;
        _status = null;
        _startDate = null;
        _dueDate = null;
        _titleController.clear();
        _descriptionController.clear();
        _projectList = DatabaseHelper().getAllProjects();
        _empList = [];
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  int no = 0;
  List<Map<String, dynamic>> _tasks = [];
  String? _status;
  String? _priority;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _status = null;
    _priority = null;
  }

  void _loadTasks() {
    _tasks = DatabaseHelper().getAllTasks();
  }

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
                DataColumn(label: Text('Task Title')),
                DataColumn(label: Text('Description')),
                DataColumn(label: Text('Project')),
                DataColumn(label: Text('Assigned To')),
                DataColumn(label: Text('Priority')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Start Date')),
                DataColumn(label: Text('End Date')),
                DataColumn(label: Text('Actions')),
              ],
              rows: _tasks.map((task) {
                no++;
                _status = task['status'];
                _priority = task['priority'];
                return DataRow(cells: [
                  DataCell(Text(no.toString())),
                  DataCell(Text(task['task_title'])),
                  DataCell(Text(task['description'].toString())),
                  DataCell(Text(DatabaseHelper().getRecordByIdAndGetColumn('project', task['project_id'], 'project_name'))),
                  DataCell(Text(DatabaseHelper().getRecordByIdAndGetColumn('employee', task['assigned_to'], 'full_name'))),
                  DataCell(
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(border: OutlineInputBorder()),
                      items: ['High', 'Medium', 'Low']
                        .map((p) => DropdownMenuItem<String>(value: p, child: Text(p))).toList(),
                          value: _priority,
                          validator: (v) => v == null ? 'Please select priority' : null,
                          onChanged: (p) {
                            DatabaseHelper().updateTaskPriority(task['id'],p!);
                            setState(() {
                              _priority = p;
                            });
                          }
                        ),
                  ),
                  DataCell(
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(border: OutlineInputBorder()),
                      items: ['Pending', 'Doing', 'Done', 'Completed']
                        .map((s) => DropdownMenuItem<String>(value: s, child: Text(s))).toList(),
                          value: _status,
                          validator: (v) => v == null ? 'Please select status' : null,
                          onChanged: (s) {
                            DatabaseHelper().updateTaskStatus(task['id'],s!);
                            setState(() {
                              _status = s;
                            });
                          }
                        ),
                    ),
                  DataCell(Text(task['task_start_date'].toString())),
                  DataCell(Text(task['task_end_date'].toString())),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          String result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => EditTaskPage(task['id'])),
                          );
                          if (result == 'refresh') {
                            setState(() {
                              _loadTasks();
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
                              content: Text(
                                  'Do you really want to delete "${task['task_title']}"?'),
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
                            DatabaseHelper().deleteTask(task['id']);
                            setState(() {
                              _loadTasks();
                            });
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
            MaterialPageRoute(builder: (_) => AddTaskPage()),
          );
          if (result == 'refresh') {
            setState(() {
              _loadTasks();
            });
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class EditTaskPage extends StatefulWidget {
  final id;
  EditTaskPage(this.id);

  @override
  State<EditTaskPage> createState() => _EditTaskPageState(id);
}

class _EditTaskPageState extends State<EditTaskPage> {
  final id;
  _EditTaskPageState(this.id);

  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();

  // Dropdown & Date
  List<Map<String, dynamic>> _projectList = [];
  List<Map<String, dynamic>> _empList = [];
  int? _selectedProjectId;
  int? _selectedEmpId;
  String? _priority;
  String? _startDate;
  String? _dueDate;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  void _loadProjects() {
    _projectList = DatabaseHelper().getAllProjects();
  }

  Future<void> _loadEmployees(int projectId) async {
    _empList = await DatabaseHelper().getEmployeesByProject(projectId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add New Task')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_titleController, 'Task Title', (v) => v!.isEmpty ? 'Please enter title' : null),
              SizedBox(height: 16),

              _buildTextField(_descriptionController, 'Description', null, maxLines: 3),
              SizedBox(height: 16),

              _buildTextField(_budgetController, 'Budget', (v) => v!.isEmpty ? 'Please enter budget' : null),
              SizedBox(height: 16),

              // Project Dropdown
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: 'Project', border: OutlineInputBorder()),
                items: _projectList.map((p) => DropdownMenuItem<int>(
                  value: p['id'],
                  child: Text(p['project_name']),
                )).toList(),
                value: _selectedProjectId,
                validator: (v) => v == null ? 'Please select project' : null,
                onChanged: (id) {
                  setState(() {
                    _selectedProjectId = id;
                    _selectedEmpId = null;
                    _empList = [];
                  });
                  if (id != null) _loadEmployees(id);
                },
              ),
              SizedBox(height: 16),

              // Assigned To Dropdown (after project)
              if (_selectedProjectId != null) ...[
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(labelText: 'Assigned To', border: OutlineInputBorder()),
                  items: _empList.map((e) => DropdownMenuItem<int>(
                    value: e['id'],
                    child: Text(e['full_name']),
                  )).toList(),
                  value: _selectedEmpId,
                  validator: (v) => v == null ? 'Please select employee' : null,
                  onChanged: (id) => setState(() => _selectedEmpId = id),
                ),
                SizedBox(height: 16),
              ],

              // Start Date Picker
              ListTile(
                title: Text(_startDate == null
                    ? 'Select Start Date'
                    : 'Start Date: $_startDate'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _startDate = picked.toIso8601String().split('T')[0]);
                },
              ),
              SizedBox(height: 16),

              // Due Date Picker
              ListTile(
                title: Text(_dueDate == null
                    ? 'Select Due Date'
                    : 'Due Date: $_dueDate'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final initial = _startDate != null ? DateTime.parse(_startDate!) : DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: initial,
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _dueDate = picked.toIso8601String().split('T')[0]);
                },
              ),
              SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Save Task'),
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
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Do you want to update?"),
        content: Text("Are you sure you want to update to ${_titleController.text}?"),
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
      
      await DatabaseHelper().updateTask(
        id,
        taskTitle: _titleController.text,
        description: _descriptionController.text,
        budget: double.parse(_budgetController.text),
        projectId: _selectedProjectId!,
        assignedTo: _selectedEmpId!,
        taskStartDate: _startDate,
        taskEndDate: _dueDate,
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
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
