
import 'package:flutter/material.dart';

class ProjectDataListPage extends StatelessWidget {
  final List<Map<String, dynamic>> projectData = [
    {'project': 'Project A', 'dataType': 'Requirements', 'version': '1.0', 'lastUpdated': '2023-05-15'},
    {'project': 'Project B', 'dataType': 'Design Docs', 'version': '2.1', 'lastUpdated': '2023-04-20'},
    {'project': 'Project C', 'dataType': 'Test Cases', 'version': '1.5', 'lastUpdated': '2023-06-05'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text('Project')),
            DataColumn(label: Text('Data Type')),
            DataColumn(label: Text('Version')),
            DataColumn(label: Text('Last Updated')),
            DataColumn(label: Text('Actions')),
          ],
          rows: projectData.map((data) {
            return DataRow(cells: [
              DataCell(Text(data['project'])),
              DataCell(Text(data['dataType'])),
              DataCell(Text(data['version'])),
              DataCell(Text(data['lastUpdated'])),
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
                  IconButton(
                    icon: Icon(Icons.download, color: Colors.green),
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
          Navigator.push(context, MaterialPageRoute(builder: (_) => AddProjectDataPage()));
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddProjectDataPage extends StatefulWidget {
  @override
  _AddProjectDataPageState createState() => _AddProjectDataPageState();
}

class _AddProjectDataPageState extends State<AddProjectDataPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _versionController = TextEditingController();
  String _project = 'Project A';
  String _dataType = 'Requirements';
  String _fileType = 'Document';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Project Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
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
                value: _dataType,
                decoration: InputDecoration(
                  labelText: 'Data Type',
                  border: OutlineInputBorder(),
                ),
                items: ['Requirements', 'Design', 'Test Cases', 'Documentation', 'Reports']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _dataType = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title/Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter title/description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _versionController,
                decoration: InputDecoration(
                  labelText: 'Version',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter version';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _fileType,
                decoration: InputDecoration(
                  labelText: 'File Type',
                  border: OutlineInputBorder(),
                ),
                items: ['Document', 'Spreadsheet', 'Presentation', 'Image', 'Other']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _fileType = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Implement file upload functionality
                },
                icon: Icon(Icons.upload),
                label: Text('Upload File'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Save Project Data'),
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
      final newProjectData = {
        'project': _project,
        'dataType': _dataType,
        'title': _titleController.text,
        'version': _versionController.text,
        'fileType': _fileType,
        'uploadDate': DateTime.now().toIso8601String(),
      };
      
      print('New Project Data: $newProjectData');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Project data added successfully')),
      );
      
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _versionController.dispose();
    super.dispose();
  }
}

