
import 'package:flutter/material.dart';

class AddTaskPage extends StatefulWidget {
  @override
  _AddTaskPageState createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _project = 'Project A';
  String _assignedTo = 'John Doe';
  String _priority = 'Medium';
  DateTime? _dueDate;
  DateTime? _startDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter task title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _project,
                decoration: InputDecoration(
                  labelText: 'Project',
                  border: OutlineInputBorder(),
                ),
                items: ['Project A', 'Project B', 'Project C']
                    .map((proj) => DropdownMenuItem(
                          value: proj,
                          child: Text(proj),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _project = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _assignedTo,
                decoration: InputDecoration(
                  labelText: 'Assigned To',
                  border: OutlineInputBorder(),
                ),
                items: ['John Doe', 'Jane Smith', 'Mike Johnson', 'Sarah Williams']
                    .map((person) => DropdownMenuItem(
                          value: person,
                          child: Text(person),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _assignedTo = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: ['High', 'Medium', 'Low']
                    .map((priority) => DropdownMenuItem(
                          value: priority,
                          child: Text(priority),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _priority = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text(_startDate == null
                    ? 'Select Start Date'
                    : 'Start Date: ${_startDate!.toLocal()}'.split(' ')[0]),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _startDate = pickedDate;
                    });
                  }
                },
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text(_dueDate == null
                    ? 'Select Due Date'
                    : 'Due Date: ${_dueDate!.toLocal()}'.split(' ')[0]),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: _startDate ?? DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _dueDate = pickedDate;
                    });
                  }
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Save Task'),
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
      final newTask = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'project': _project,
        'assignedTo': _assignedTo,
        'priority': _priority,
        'startDate': _startDate?.toIso8601String(),
        'dueDate': _dueDate?.toIso8601String(),
        'status': 'Pending',
      };
      
      print('New Task: $newTask');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task added successfully')),
      );
      
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class TaskListPage extends StatelessWidget {
  final List<Map<String, dynamic>> tasks = [
    {'title': 'UI Design', 'project': 'Project A', 'assignedTo': 'John Doe', 'status': 'In Progress', 'dueDate': '2023-06-15'},
    {'title': 'API Development', 'project': 'Project B', 'assignedTo': 'Jane Smith', 'status': 'Completed', 'dueDate': '2023-05-20'},
    {'title': 'Testing', 'project': 'Project C', 'assignedTo': 'Mike Johnson', 'status': 'Pending', 'dueDate': '2023-07-10'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text('Task Title')),
            DataColumn(label: Text('Project')),
            DataColumn(label: Text('Assigned To')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Due Date')),
            DataColumn(label: Text('Actions')),
          ],
          rows: tasks.map((task) {
            return DataRow(cells: [
              DataCell(Text(task['title'])),
              DataCell(Text(task['project'])),
              DataCell(Text(task['assignedTo'])),
              DataCell(
                Chip(
                  label: Text(task['status']),
                  backgroundColor: task['status'] == 'Completed' 
                    ? Colors.green[100] 
                    : task['status'] == 'In Progress' 
                      ? Colors.blue[100] 
                      : Colors.orange[100],
                ),
              ),
              DataCell(Text(task['dueDate'])),
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
          Navigator.push(context, MaterialPageRoute(builder: (_) => AddTaskPage()));
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
