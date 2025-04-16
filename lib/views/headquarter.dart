import 'package:flutter/material.dart';
import 'package:pms/util/database_util.dart';
import 'package:pms/views/addon/alertdialog.dart';

class AddHQPage extends StatefulWidget {
  @override
  _AddHQPageState createState() => _AddHQPageState();
}

class _AddHQPageState extends State<AddHQPage> {
  final TextEditingController location = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add HQ')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: location,
                decoration: InputDecoration(
                  labelText: 'HQ Location',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (location.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter an HQ location')),
                      );
                    } else {
                      DatabaseHelper().insertHQ(location.text.trim());
                      bool confirm = await AddAnother(context, "HQ", [location]);
                      if (confirm == true) {
                        // do nothing
                      }
                      else Navigator.pop(context,'refresh');
                    }
                  },
                  child: Text('Save HQ Location'),
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
    location.dispose();
    super.dispose();
  }
}

class HQListPage extends StatefulWidget {
  const HQListPage({super.key});

  @override
  State<HQListPage> createState() => _HQListPageState();
}

class _HQListPageState extends State<HQListPage> {
  @override
  Widget build(BuildContext context) {
    int index = 0;
    
    return Scaffold(
      body: SizedBox(
        height: MediaQuery.sizeOf(context).height,
        width: MediaQuery.sizeOf(context).width,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columns: [
              DataColumn(label: Text('No')),
              DataColumn(label: Text('HQ Location')),
              DataColumn(label: Text('Actions')),
            ],
            rows: DatabaseHelper().getAllHQ().map((hq) {
              index++;
              return DataRow(cells: [
                  DataCell(Text(index.toString())),
                  DataCell(Text(hq['location'])),
                  DataCell(Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () async {
                        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditHQPage(hq['id'],hq['location'])));
                        if (result == 'refresh'){
                          setState(() {
                            // update UI
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
                            content: Text('Do you really want to delete ${hq['location']}?'),
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
                          await DatabaseHelper().deleteHQ(hq['id']);
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
        onPressed: () async{
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddHQPage()));
          if (result == 'refresh'){
            setState(() {
              // update UI
            });
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class EditHQPage extends StatefulWidget {
  final int id;
  final String location;
  EditHQPage(this.id, this.location);
  
  @override
  State<EditHQPage> createState() => _EditHQPageState(id,location);
}

class _EditHQPageState extends State<EditHQPage> {
  bool isUpdate = false;
  final int id;
  final String location;
  _EditHQPageState(this.id,this.location);
  final TextEditingController locationText = TextEditingController();

  @override
  Widget build(BuildContext context) {
    locationText.text = location;
    if (isUpdate==false) {}
    else { Navigator.pop(context, 'refresh'); }
    return Scaffold(
      appBar: AppBar(title: Text('Add HQ')),
      body: SizedBox(
        width: MediaQuery.sizeOf(context).width,
        height: MediaQuery.sizeOf(context).height,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: locationText,
                decoration: InputDecoration(
                  labelText: 'HQ Location',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (locationText.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter an HQ location')),
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Do you really want to change?'),
                          content: Text('Do you want to change $location to ${locationText.text}?'),
                          actions: [
                            TextButton(
                              child: Text('Yes'),
                              onPressed: () {
                                setState(() {
                                  isUpdate = !isUpdate;
                                });                    
                                DatabaseHelper().updateHQ(id,locationText.text.toString().trim());
                                Navigator.pop(context);
                              },
                            ),
                            TextButton(
                              child: Text('No'),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  child: Text('Save HQ Location'),
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
    locationText.dispose();
    super.dispose();
  }
}