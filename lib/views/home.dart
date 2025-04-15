import 'package:flutter/material.dart';
import 'package:pms/views/dashboard.dart';
import 'package:pms/views/department.dart';
import 'package:pms/views/employee.dart';
import 'package:pms/views/headquarter.dart';
import 'package:pms/views/login.dart';
import 'package:pms/views/project.dart';
import 'package:pms/views/project_data.dart';
import 'package:pms/views/task.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _selectedProject = 'Select Project';

  final List<Widget> _pages = [
    DashboardPage(),
    HQListPage(),
    ProjectListPage(),
    DepartmentListPage(),
    EmployeeListPage(),
    TaskListPage(),
    ProjectDataListPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Project Management System'),
        actions: [
          IconButton(icon: Icon(Icons.notifications), onPressed: () {}),
          IconButton(icon: Icon(Icons.account_circle), onPressed: () {}),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    child: Icon(Icons.person, size: 40),
                  ),
                  SizedBox(height: 10),
                  Text('Admin User', style: TextStyle(color: Colors.white, fontSize: 18)),
                  Text('admin@company.com', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ExpansionTile(
              leading: Icon(Icons.work),
              title: Text('HQ'),
              children: [
                ListTile(
                  title: Text('Add Headquarter'),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AddHQPage()));
                  },
                ),
                ListTile(
                  title: Text('Headquarter List'),
                  selected: _selectedIndex == 1,
                  onTap: () {
                    setState(() => _selectedIndex = 1);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            ExpansionTile(
              leading: Icon(Icons.work),
              title: Text('Projects'),
              children: [
                ListTile(
                  title: Text('Add Project'),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AddProjectPage()));
                  },
                ),
                ListTile(
                  title: Text('Project List'),
                  selected: _selectedIndex == 2,
                  onTap: () {
                    setState(() => _selectedIndex = 2);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            ExpansionTile(
              leading: Icon(Icons.business),
              title: Text('Departments'),
              children: [
                ListTile(
                  title: Text('Add Department'),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AddDepartmentPage()));
                  },
                ),
                ListTile(
                  title: Text('Department List'),
                  selected: _selectedIndex == 3,
                  onTap: () {
                    setState(() => _selectedIndex = 3);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            ExpansionTile(
              leading: Icon(Icons.people),
              title: Text('Employees'),
              children: [
                ListTile(
                  title: Text('Add Employee'),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AddEmployeePage()));
                  },
                ),
                ListTile(
                  title: Text('Employee List'),
                  selected: _selectedIndex == 4,
                  onTap: () {
                    setState(() => _selectedIndex = 4);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            ExpansionTile(
              leading: Icon(Icons.task),
              title: Text('Tasks'),
              children: [
                ListTile(
                  title: Text('Add Task'),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AddTaskPage()));
                  },
                ),
                ListTile(
                  title: Text('Task List'),
                  selected: _selectedIndex == 5,
                  onTap: () {
                    setState(() => _selectedIndex = 5);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            ExpansionTile(
              leading: Icon(Icons.data_usage),
              title: Text('Project Data'),
              children: [
                ListTile(
                  title: Text('Add Project Data'),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AddProjectDataPage()));
                  },
                ),
                ListTile(
                  title: Text('Project Data List'),
                  selected: _selectedIndex == 6,
                  onTap: () {
                    setState(() => _selectedIndex = 6);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage()));
              },
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}


