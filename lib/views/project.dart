import 'package:flutter/material.dart';
import 'package:pms/util/database_util.dart';
import 'package:pms/views/addon/alertdialog.dart';

class AddProjectPage extends StatefulWidget {
  @override
  _AddProjectPageState createState() => _AddProjectPageState();
}

class _AddProjectPageState extends State<AddProjectPage> {
  final _projectNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimateCostController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedHQ;
  String? _status;

  late List<Map<String,dynamic>> hq;

  @override
  void initState() {
    super.initState();
    hq = DatabaseHelper().getAllHQ();
  }

  @override
  Widget build(BuildContext context) {
    List<String> _hq = [];
    List<int> _hqID = [];
    for (int i=0; i<hq.length; i++){
      Map<String,dynamic> _temp = hq[i];
      _hq.add(_temp['location']);
      _hqID.add(_temp['id']);
    }

    return Scaffold(
      appBar: AppBar(title: Text('Add Project')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _projectNameController,
                decoration: InputDecoration(
                  labelText: 'Project Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                value: _status,
                items: ["Initiate","Pending","Ongoing","Completed"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _status = newValue;
                  });
                },
              ),
              SizedBox(height: 16),
              
              // Start Date picker
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  //labelText: 'Start Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                  hintText: _startDate == null
                      ? 'Select Start Date'
                      : '${_startDate!.toLocal()}'.split(' ')[0],
                ),
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
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

              // End Date picker
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  //labelText: 'End Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                  hintText: _endDate == null
                      ? 'Select End Date'
                      : '${_endDate!.toLocal()}'.split(' ')[0],
                ),
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _endDate = pickedDate;
                    });
                  }
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
              
              TextField(
                controller: _estimateCostController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Estimate Cost',
                  border: OutlineInputBorder(),
                  errorText: _validateInput() ? 'Invalid number' : null,
                ),
                maxLines: 1,
              ),
              SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_projectNameController.text.isEmpty ||
                        _descriptionController.text.isEmpty ||
                        _status == null ||
                        _startDate == null ||
                        _endDate == null ||
                        _selectedHQ == null ||
                        _estimateCostController.text.isEmpty ||
                        _validateInput()) {
                      // Show alert if any field is invalid
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Missing or Invalid Fields'),
                          content: Text('Please fill in all fields correctly before saving.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('OK'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // Save to database
                      DatabaseHelper().insertProject(
                        projectName: _projectNameController.text,
                        description: _descriptionController.text,
                        status: _status.toString(),
                        startDate: _startDate!.toLocal().toString().split(' ')[0],
                        endDate: _endDate!.toLocal().toString().split(' ')[0],
                        hqId: _hqID[_hq.indexOf("$_selectedHQ")],
                        estimatedCost: double.tryParse(_estimateCostController.text),
                      );

                      bool confirm = await AddAnother(context, "Project", [_projectNameController,_descriptionController,_estimateCostController]);
                      if (confirm==false) {Navigator.pop(context,'refresh');};
                    }
                    print('Project Name: ${_projectNameController.text}');
                    print('Description: ${_descriptionController.text}');
                    print('Start Date: ${'${_startDate!.toLocal()}'.split(' ')[0] }');
                    print('End Date: ${'${_endDate!.toLocal()}'.split(' ')[0] }');
                    print('HQ: $_selectedHQ');
                    print('Estimate cost: $_estimateCostController');
                  },
                  child: Text('Save Project'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _validateInput() {
  final text = _estimateCostController.text.trim();
  if (text.isEmpty) return false;
  return double.tryParse(text) == null;
}
}

class ProjectListPage extends StatefulWidget {
  const ProjectListPage({super.key});

  @override
  State<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends State<ProjectListPage> {
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
              DataColumn(label: Text('Project Name')),
              DataColumn(label: Text('Description')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Start Date')),
              DataColumn(label: Text('End Date')),
              DataColumn(label: Text('HQ')),
              DataColumn(label: Text('Actions')),
            ],
            rows: DatabaseHelper().getAllProjects().map((project) {
              return DataRow(cells: [
                DataCell(Text(project['project_name'])),
                DataCell(Text(project['description'])),
                DataCell(
                  Chip(
                    label: Text(project['status']),
                    backgroundColor: project['status'] == 'Completed' 
                      ? Colors.green[100] 
                      : project['status'] == "Ongoing" 
                        ? Colors.blue[100] 
                        : project['status'] == "Pending"
                          ? Colors.orange[100]
                          : Colors.yellow[100],
                  ),
                ),
                DataCell(Text(project['start_date'])),
                DataCell(Text(project['end_date'])),
                DataCell(Text(
                  DatabaseHelper().getRecordByIdAndGetColumn("hq", project['hq_id'],"location").toString()),
                ),
                DataCell(Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_red_eye_outlined, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ViewProjectPage(project['id'])));
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () async {
                        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditProjectPage(project['id'])));
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
                            content: Text('Do you really want to delete ${project['project_name']}?'),
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
                          await DatabaseHelper().deleteProject(project['id']);
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
        onPressed: () async {
          String result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddProjectPage()));
          if(result=='refresh') {
            setState(() {});
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class ViewProjectPage extends StatefulWidget {
  final int id;
  ViewProjectPage(this.id);

  @override
  _ViewProjectPageState createState() => _ViewProjectPageState(id);
}

class _ViewProjectPageState extends State<ViewProjectPage> {
  final int id;
  _ViewProjectPageState(this.id);

  late List<Map<String,dynamic>> hq;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Map<String,dynamic> data =  DatabaseHelper().getRecordById('project',id)!;

    return Scaffold(
      appBar: AppBar(title: Text('Add Project')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                data['project_name'],
              ),
              SizedBox(height: 16),

              Text(
                data['description']
              ),
              SizedBox(height: 16),

              Text(
                data['status']
              ),
              SizedBox(height: 16),
              
              // Start Date picker
              Text(
                data['start_date']
              ),
              SizedBox(height: 16),

              // End Date picker
              Text(
                data['end_date']
              ),
              SizedBox(height: 16),

              Text(
                DatabaseHelper().getRecordByIdAndGetColumn("hq", data['hq_id'],"location").toString(),
              ),
              SizedBox(height: 16),
              
              Text(
                data['estimated_cost'].toString()
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class EditProjectPage extends StatefulWidget {
  final int id;
  EditProjectPage(this.id);
  
  @override
  _EditProjectPageState createState() => _EditProjectPageState(id);
}

class _EditProjectPageState extends State<EditProjectPage> {
  final int id;
  _EditProjectPageState(this.id);

  final _projectNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimateCostController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedHQ;
  String? _status;
  late Map<String,dynamic> data;

  late List<Map<String,dynamic>> hq;

  @override
  void initState() {
    super.initState();
    hq = DatabaseHelper().getAllHQ();
    data =  DatabaseHelper().getRecordById('project',id)!;
    _projectNameController.text = data['project_name'];
    _descriptionController.text = data['description'];
    _estimateCostController.text = data['estimated_cost'].toString();
  }

  @override
  Widget build(BuildContext context) {
    // This method is wrong set in init
    // _projectNameController.text = data['project_name'];
    // _descriptionController.text = data['description'];
    // _estimateCostController.text = data['estimated_cost'].toString();

    List<String> _hq = [];
    List<int> _hqID = [];
    for (int i=0; i<hq.length; i++){
      Map<String,dynamic> _temp = hq[i];
      _hq.add(_temp['location']);
      _hqID.add(_temp['id']);
    }

    return Scaffold(
      appBar: AppBar(title: Text('Add Project')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _projectNameController,
                decoration: InputDecoration(
                  labelText: 'Project Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                value: _status,
                items: ["Initiate","Pending","Ongoing","Completed"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _status = newValue;
                  });
                },
              ),
              SizedBox(height: 16),
              
              // Start Date picker
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  //labelText: 'Start Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                  hintText: _startDate == null
                      ? data['start_date']
                      : '${_startDate!.toLocal()}'.split(' ')[0],
                ),
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
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

              // End Date picker
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  //labelText: 'End Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                  hintText: _endDate == null
                      ? data['end_date']
                      : '${_endDate!.toLocal()}'.split(' ')[0],
                ),
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _endDate = pickedDate;
                    });
                  }
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
              
              TextField(
                controller: _estimateCostController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Estimate Cost',
                  border: OutlineInputBorder(),
                  errorText: _validateInput() ? 'Invalid number' : null,
                ),
                maxLines: 1,
              ),
              SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_projectNameController.text.isEmpty ||
                        _descriptionController.text.isEmpty ||
                        _status == null ||
                        _startDate == null ||
                        _endDate == null ||
                        _selectedHQ == null ||
                        _estimateCostController.text.isEmpty ||
                        _validateInput()) {
                      // Show alert if any field is invalid
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Missing or Invalid Fields'),
                          content: Text('Please fill in all fields correctly before saving.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('OK'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // Save to database
                      DatabaseHelper().updateProject(
                        data['id'],
                        projectName: _projectNameController.text,
                        description: _descriptionController.text,
                        status: _status,
                        startDate: _startDate!.toLocal().toString().split(' ')[0],
                        endDate: _endDate!.toLocal().toString().split(' ')[0],
                        hq: _hqID[_hq.indexOf("$_selectedHQ")],
                        estimatedCost: double.tryParse(_estimateCostController.text),
                      );
                      Navigator.pop(context, 'refresh');
                    }
                    print('Project Name: ${_projectNameController.text}');
                    print('Description: ${_descriptionController.text}');
                    print('Start Date: ${'${_startDate!.toLocal()}'.split(' ')[0] }');
                    print('End Date: ${'${_endDate!.toLocal()}'.split(' ')[0] }');
                    print('HQ: $_selectedHQ');
                    print('Estimate cost: $_estimateCostController');
                  },
                  child: Text('Save Project'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _validateInput() {
  final text = _estimateCostController.text.trim();
  if (text.isEmpty) return false;
  return double.tryParse(text) == null;
}
}

