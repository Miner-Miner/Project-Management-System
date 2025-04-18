import 'dart:developer';
import 'dart:io';

import 'package:pms/util/crypt_util.dart';
import 'package:sqlite3/sqlite3.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  late final Database _db;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal() {
    _initDb();
  }

  void _initDb() {
    final dbPath = '${Directory.current.path}/database/admin_database.sqlite';
    _db = sqlite3.open(dbPath);
    _createTables();
  }

  void _createTables() {
    _db.execute('PRAGMA foreign_keys = ON;');
    // Create Admin Data Table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS admin_login (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      );
    ''');

    // Create HQ Data Table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS hq (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        location TEXT UNIQUE NOT NULL
      );
    ''');

    // Create Department Table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS department (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        department_name TEXT NOT NULL,
        department_head_name TEXT NOT NULL,
        hq_id INTEGER NOT NULL,
        FOREIGN KEY (hq_id) REFERENCES hq(id) ON DELETE CASCADE
      );
    ''');

    // Create Employee Table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS employee (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hq_id INTEGER NOT NULL,
        full_name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone_number TEXT,
        address TEXT,
        department_id INTEGER NOT NULL,
        position TEXT NOT NULL,
        skill TEXT,
        hire_date TEXT,
        FOREIGN KEY (hq_id) REFERENCES hq(id) ON DELETE CASCADE,
        FOREIGN KEY (department_id) REFERENCES department(id) ON DELETE CASCADE
      );
    ''');

    // Create Project Table
    // estimated_cost is planned value (PV)
    _db.execute('''
      CREATE TABLE IF NOT EXISTS project (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_name TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        hq_id INTEGER NOT NULL,
        estimated_cost REAL,
        FOREIGN KEY (hq_id) REFERENCES hq(id) ON DELETE CASCADE
      );
    ''');

    // Create Task Table
    // budget is “baseline” for EV
    _db.execute('''
      CREATE TABLE IF NOT EXISTS task (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_title TEXT NOT NULL,
        description TEXT,
        project_id INTEGER NOT NULL,
        assigned_to INTEGER,
        priority TEXT,
        status TEXT,
        task_start_date TEXT,
        task_end_date TEXT,
        budget           REAL    NOT NULL DEFAULT 0.0,
        FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE,
        FOREIGN KEY (assigned_to) REFERENCES employee(id) ON DELETE CASCADE
      );
    ''');

    // Create Project Data Table
    // cost is actual‐cost line items (AC)
    _db.execute('''
      CREATE TABLE IF NOT EXISTS data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        description TEXT,
        cost REAL NOT NULL,
        FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE
      );
    ''');
  }

  // Helper function: Converts a Row to a Map<String, dynamic>
  Map<String, dynamic> _rowToMap(Row row, List<String> columnNames) {
    final map = <String, dynamic>{};
    for (int i = 0; i < columnNames.length; i++) {
      map[columnNames[i]] = row[columnNames[i]];
    }
    return map;
  }

   // ===================== ADMIN_LOGIN CRUD =====================

  bool insertAdmin(String username, String password) {
    try {
      _db.execute(
        'INSERT INTO admin_login (username, password) VALUES (?, ?)',
        [username, password],
      );
      return true;
    } catch (e) {
      log('Insert Admin Failed: $e');
      return false;
    }
  }

  List<Map<String, dynamic>> getAllAdmins() {
    final List<Map<String, dynamic>> admins = [];
    try {
      final result = _db.select('SELECT * FROM admin_login');
      final columnNames = result.columnNames;
      for (final row in result) {
        admins.add(_rowToMap(row,columnNames));
      }
    } catch (e) {
      log('Get Admins Failed: $e');
    }
    return admins;
  }

  bool updateAdmin(int id, {String? username, String? password}) {
    try {
      final fields = <String>[];
      final values = <dynamic>[];
      if (username != null) {
        fields.add('username = ?');
        values.add(username);
      }
      if (password != null) {
        fields.add('password = ?');
        values.add(password);
      }
      if (fields.isEmpty) return false;
      values.add(id);
      _db.execute('UPDATE admin_login SET ${fields.join(', ')} WHERE id = ?', values);
      return true;
    } catch (e) {
      log('Update Admin Failed: $e');
      return false;
    }
  }

  bool deleteAdmin(int id) {
    try {
      _db.execute('DELETE FROM admin_login WHERE id = ?', [id]);
      return true;
    } catch (e) {
      log('Delete Admin Failed: $e');
      return false;
    }
  }

  // ===================== HQ CRUD =====================

  bool insertHQ(String location) {
    try {
      _db.execute('INSERT INTO hq (location) VALUES (?)', [location]);
      return true;
    } catch (e) {
      log('Insert HQ Failed: $e');
      return false;
    }
  }

  List<Map<String, dynamic>> getAllHQ() {
    final List<Map<String, dynamic>> hqList = [];
    try {
      final result = _db.select('SELECT * FROM hq');
      final columnNames = result.columnNames;
      for (final row in result) {
        hqList.add(_rowToMap(row,columnNames));
      }
    } catch (e) {
      log('Get HQ Failed: $e');
    }
    return hqList;
  }

  bool updateHQ(int id, String location) {
    try {
      _db.execute('UPDATE hq SET location = ? WHERE id = ?', [location, id]);
      return true;
    } catch (e) {
      log('Update HQ Failed: $e');
      return false;
    }
  }

  bool deleteHQ(int id) {
    try {
      _db.execute('DELETE FROM hq WHERE id = ?', [id]);
      return true;
    } catch (e) {
      log('Delete HQ Failed: $e');
      return false;
    }
  }
  
  List<Map<String, dynamic>> getDepartmentsByHq(int hqId) {
    final List<Map<String, dynamic>> departments = [];
    try {
      // Use your low‑level select API
      final result = _db.select(
        'SELECT id, department_name, department_head_name, hq_id '
        'FROM department WHERE hq_id = ?',
        [hqId],
      );

      // Convert each Row into a Map<String, dynamic>
      final columnNames = result.columnNames;
      for (final row in result) {
        departments.add(_rowToMap(row, columnNames));
      }
    } catch (e) {
      log('Get Departments by HQ Failed: $e');
    }
    return departments;
  }

  // ===================== DEPARTMENT CRUD =====================

  bool insertDepartment(String departmentName, String departmentHeadName, int hqId) {
    try {
      _db.execute(
        'INSERT INTO department (department_name, department_head_name, hq_id) VALUES (?, ?, ?)',
        [departmentName, departmentHeadName, hqId],
      );
      return true;
    } catch (e) {
      log('Insert Department Failed: $e');
      return false;
    }
  }

  List<Map<String, dynamic>> getAllDepartments() {
    final List<Map<String, dynamic>> departments = [];
    try {
      final result = _db.select('SELECT * FROM department');
      final columnNames = result.columnNames;
      for (final row in result) {
        departments.add(_rowToMap(row,columnNames));
      }
    } catch (e) {
      log('Get Departments Failed: $e');
    }
    return departments;
  }

  bool updateDepartment(int id, {String? departmentName, String? departmentHeadName, int? hqId}) {
    try {
      final fields = <String>[];
      final values = <dynamic>[];
      if (departmentName != null) {
        fields.add('department_name = ?');
        values.add(departmentName);
      }
      if (departmentHeadName != null) {
        fields.add('department_head_name = ?');
        values.add(departmentHeadName);
      }
      if (hqId != null) {
        fields.add('hq_id = ?');
        values.add(hqId);
      }
      if (fields.isEmpty) return false;
      values.add(id);
      _db.execute('UPDATE department SET ${fields.join(', ')} WHERE id = ?', values);
      return true;
    } catch (e) {
      log('Update Department Failed: $e');
      return false;
    }
  }

  bool deleteDepartment(int id) {
    try {
      _db.execute('DELETE FROM department WHERE id = ?', [id]);
      return true;
    } catch (e) {
      log('Delete Department Failed: $e');
      return false;
    }
  }

  List<Map<String, dynamic>> getEmployeeCountByDepartment() {
    try {
      final result = _db.select(
        'SELECT department_id, COUNT(*) AS count FROM employee GROUP BY department_id',
      );
      // Convert the result into a List of Maps
      List<Map<String, dynamic>> counts = [];
      for (final row in result) {
        counts.add({
          'department_id': row['department_id'],
          'count': row['count'],
        });
      }
      return counts;
    } catch (e) {
      log('Get Employee Count by Department Failed: $e');
      return [];
    }
  }

  int getEmployeeCountForDepartment(int departmentId) {
    try {
      final result = _db.select(
        'SELECT COUNT(*) AS count FROM employee WHERE department_id = ?',
        [departmentId],
      );
      if (result.isNotEmpty) {
        return result.first['count'] as int;
      } else {
        return 0;
      }
    } catch (e) {
      log('Get Employee Count for Department Failed: $e');
      return 0;
    }
  }

  // ===================== EMPLOYEE CRUD =====================

  bool insertEmployee({
    required String fullName,
    required String email,
    String? phoneNumber,
    String? address,
    required int hqId,
    required int departmentId,
    required String position,
    String? skill,
    String? hireDate,
  }) {
    try {
      _db.execute('''
        INSERT INTO employee (hq_id,full_name, email, phone_number, address, department_id, position, skill, hire_date)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [hqId, fullName, email, phoneNumber, address, departmentId, position, skill, hireDate]);
      return true;
    } catch (e) {
      log('Insert Employee Failed: $e');
      return false;
    }
  }

  List<Map<String, dynamic>> getAllEmployees() {
    final List<Map<String, dynamic>> employees = [];
    try {
      final result = _db.select('SELECT * FROM employee');
      final columnNames = result.columnNames;
      for (final row in result) {
        employees.add(_rowToMap(row,columnNames));
      }
    } catch (e) {
      log('Get Employees Failed: $e');
    }
    return employees;
  }

  bool updateEmployee(
    int id, {
    String? fullName,
    String? email,
    String? phoneNumber,
    String? address,
    int? hqId,
    int? departmentId,
    String? position,
    String? skill,
    String? hireDate,
  }) {
    try {
      final fields = <String>[];
      final values = <dynamic>[];
      if (fullName != null) {
        fields.add('full_name = ?');
        values.add(fullName);
      }
      if (email != null) {
        fields.add('email = ?');
        values.add(email);
      }
      if (phoneNumber != null) {
        fields.add('phone_number = ?');
        values.add(phoneNumber);
      }
      if (address != null) {
        fields.add('address = ?');
        values.add(address);
      }
      if (hqId != null) {
        fields.add('hq_id = ?');
        values.add(hqId);
      }
      if (departmentId != null) {
        fields.add('department_id = ?');
        values.add(departmentId);
      }
      if (position != null) {
        fields.add('position = ?');
        values.add(position);
      }
      if (skill != null) {
        fields.add('skill = ?');
        values.add(skill);
      }
      if (hireDate != null) {
        fields.add('hire_date = ?');
        values.add(hireDate);
      }
      if (fields.isEmpty) return false;
      values.add(id);
      _db.execute('UPDATE employee SET ${fields.join(', ')} WHERE id = ?', values);
      return true;
    } catch (e) {
      log('Update Employee Failed: $e');
      return false;
    }
  }

  bool deleteEmployee(int id) {
    try {
      _db.execute('DELETE FROM employee WHERE id = ?', [id]);
      return true;
    } catch (e) {
      log('Delete Employee Failed: $e');
      return false;
    }
  }

  // ===================== TASK CRUD =====================

  bool insertTask({
    required String taskTitle,
    String? description,
    required double budget,
    required int projectId,
    int? assignedTo,
    String? priority,
    String? status,
    String? taskStartDate,
    String? taskEndDate,
  }) {
    try {
      _db.execute('''
        INSERT INTO task (task_title, description, budget, project_id, assigned_to, priority, status, task_start_date, task_end_date)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [taskTitle, description, budget, projectId, assignedTo, priority, status, taskStartDate, taskEndDate]);
      return true;
    } catch (e) {
      log('Insert Task Failed: $e');
      return false;
    }
  }

  List<Map<String, dynamic>> getAllTasks() {
    final List<Map<String, dynamic>> tasks = [];
    try {
      final result = _db.select('SELECT * FROM task');
      final columnNames = result.columnNames;
      for (final row in result) {
        tasks.add(_rowToMap(row,columnNames));
      }
    } catch (e) {
      log('Get Tasks Failed: $e');
    }
    return tasks;
  }

  bool updateTask(
    int id, {
    String? taskTitle,
    String? description,
    double? budget,
    int? projectId,
    int? assignedTo,
    String? priority,
    String? status,
    String? taskStartDate,
    String? taskEndDate,
  }) {
    try {
      final fields = <String>[];
      final values = <dynamic>[];
      if (taskTitle != null) {
        fields.add('task_title = ?');
        values.add(taskTitle);
      }
      if (description != null) {
        fields.add('description = ?');
        values.add(description);
      }
      if (budget != null) {
        fields.add('budget = ?');
        values.add(budget);
      }
      if (projectId != null) {
        fields.add('project_id = ?');
        values.add(projectId);
      }
      if (assignedTo != null) {
        fields.add('assigned_to = ?');
        values.add(assignedTo);
      }
      if (priority != null) {
        fields.add('priority = ?');
        values.add(priority);
      }
      if (status != null) {
        fields.add('status = ?');
        values.add(status);
      }
      if (taskStartDate != null) {
        fields.add('task_start_date = ?');
        values.add(taskStartDate);
      }
      if (taskEndDate != null) {
        fields.add('task_end_date = ?');
        values.add(taskEndDate);
      }
      if (fields.isEmpty) return false;
      values.add(id);
      _db.execute('UPDATE task SET ${fields.join(', ')} WHERE id = ?', values);
      return true;
    } catch (e) {
      log('Update Task Failed: $e');
      return false;
    }
  }

  bool deleteTask(int id) {
    try {
      _db.execute('DELETE FROM task WHERE id = ?', [id]);
      return true;
    } catch (e) {
      log('Delete Task Failed: $e');
      return false;
    }
  }

  bool updateTaskStatus(int id, String status){
    try{
      _db.execute("UPDATE task SET status = ? WHERE id = ?",[status, id]);
      log('success');
      return true;
    }
    catch(e){
      log(e.toString());
      return false;
    }
  }

  bool updateTaskPriority(int id, String priority){
    try{
      _db.execute("UPDATE task SET priority = ? WHERE id = ?",[priority, id]);
      log('success');
      return true;
    }
    catch(e){
      log(e.toString());
      return false;
    }
  }

  // ===================== PROJECT CRUD =====================

  bool insertProject({
    required String projectName,
    required String description,
    required String status,
    required String startDate,
    required String endDate,
    required int hqId,
    required double? estimatedCost,
  }) {
    try {
      _db.execute('''
        INSERT INTO project (project_name, description, status, start_date, end_date, hq_id, estimated_cost)
        VALUES (?, ?, ?, ?, ? , ? , ?)
      ''', [projectName, description, status, startDate, endDate, hqId, estimatedCost]);
      return true;
    } catch (e) {
      log('Insert Project Failed: $e');
      return false;
    }
  }

  List<Map<String, dynamic>> getAllProjects() {
    final List<Map<String, dynamic>> projects = [];
    try {
      final result = _db.select('SELECT * FROM project');
      final columnNames = result.columnNames;
      for (final row in result) {
        projects.add(_rowToMap(row,columnNames));
      }
    } catch (e) {
      log('Get Projects Failed: $e');
    }
    return projects;
  }

  bool updateProject(
    int id, {
    String? projectName,
    String? description,
    String? status,
    String? startDate,
    String? endDate,
    int? hq,
    double? estimatedCost,
  }) {
    try {
      final fields = <String>[];
      final values = <dynamic>[];
      if (projectName != null) {
        fields.add('project_name = ?');
        values.add(projectName);
      }
      if (description != null) {
        fields.add('description = ?');
        values.add(description);
      }
      if (status != null) {
        fields.add('status = ?');
        values.add(status);
      }
      if (startDate != null) {
        fields.add('start_date = ?');
        values.add(startDate);
      }
      if (endDate != null) {
        fields.add('end_date = ?');
        values.add(endDate);
      }
      if (hq != null) {
        fields.add('hq_id = ?');
        values.add(hq);
      }
      if (estimatedCost != null) {
        fields.add('estimated_cost = ?');
        values.add(estimatedCost);
      }
      if (fields.isEmpty) return false;
      values.add(id);
      _db.execute('UPDATE project SET ${fields.join(', ')} WHERE id = ?', values);
      return true;
    } catch (e) {
      log('Update Project Failed: $e');
      return false;
    }
  }

  bool deleteProject(int id) {
    try {
      _db.execute('DELETE FROM project WHERE id = ?', [id]);
      return true;
    } catch (e) {
      log('Delete Project Failed: $e');
      return false;
    }
  }

  List<Map<String, dynamic>> getEmployeesByProject(int projectId) {
    final List<Map<String, dynamic>> employees = [];
    try {
      final result = _db.select(
        '''
        SELECT 
          e.id,
          e.hq_id,
          e.full_name,
          e.email,
          e.phone_number,
          e.address,
          e.department_id,
          e.position,
          e.skill,
          e.hire_date
        FROM project   AS p
        JOIN hq        AS h ON p.hq_id         = h.id
        JOIN department AS d ON d.hq_id        = h.id
        JOIN employee  AS e ON e.department_id = d.id
        WHERE p.id = ?
        ''',
        [projectId],
      );
      final columnNames = result.columnNames;
      for (final row in result) {
        employees.add(_rowToMap(row, columnNames));
      }
    } catch (e) {
      log('Get Employees By Project Failed: $e');
    }
    return employees;
  }

  /// Returns all data rows for a given project_id
  Future<List<Map<String, dynamic>>> getProjectDataByProject(int projectId) async {
    final List<Map<String, dynamic>> dataList = [];
    try {
      final result = _db.select(
        '''
        SELECT id,
              project_id,
              date,
              description,
              cost
          FROM data
        WHERE project_id = ?
        ORDER BY date DESC
        ''',
        [projectId],
      );
      final columnNames = result.columnNames;
      for (final row in result) {
        dataList.add(_rowToMap(row, columnNames));
      }
    } catch (e) {
      log('getProjectDataByProject failed: $e');
    }
    return dataList;
  }

  /// Returns all tasks for a given project_id
  Future<List<Map<String, dynamic>>> getTasksByProject(int projectId) async {
    final List<Map<String, dynamic>> taskList = [];
    try {
      final result = _db.select(
        '''
        SELECT id,
              task_title,
              description,
              project_id,
              assigned_to,
              priority,
              task_start_date,
              task_end_date
          FROM task
        WHERE project_id = ?
        ORDER BY task_start_date ASC
        ''',
        [projectId],
      );
      final columnNames = result.columnNames;
      for (final row in result) {
        taskList.add(_rowToMap(row, columnNames));
      }
    } catch (e) {
      log('getTasksByProject failed: $e');
    }
    return taskList;
  }

  // ===================== DATA CRUD =====================

  bool insertData({
    required int projectId,
    String? description,
    required double cost,
    required String date,
  }) {
    try {
      _db.execute('''
        INSERT INTO data (project_id, description, cost, date)
        VALUES (?, ?, ?, ?)
      ''', [projectId, description, cost, date]);
      return true;
    } catch (e) {
      log('Insert Data Failed: $e');
      return false;
    }
  }

  List<Map<String, dynamic>> getAllData() {
    final List<Map<String, dynamic>> dataList = [];
    try {
      final result = _db.select('SELECT * FROM data');
      final columnNames = result.columnNames;
      for (final row in result) {
        dataList.add(_rowToMap(row,columnNames));
      }
    } catch (e) {
      log('Get Data Failed: $e');
    }
    return dataList;
  }

  bool updateData(
    int id, {
    int? projectId,
    String? description,
    double? cost,
    String? date,
  }) {
    try {
      final fields = <String>[];
      final values = <dynamic>[];
      if (projectId != null) {
        fields.add('project_id = ?');
        values.add(projectId);
      }
      if (description != null) {
        fields.add('description = ?');
        values.add(description);
      }
      if (cost != null) {
        fields.add('cost = ?');
        values.add(cost);
      }
      if (date != null) {
        fields.add('date = ?');
        values.add(date);
      }
      if (fields.isEmpty) return false;
      values.add(id);
      _db.execute('UPDATE data SET ${fields.join(', ')} WHERE id = ?', values);
      return true;
    } catch (e) {
      log('Update Data Failed: $e');
      return false;
    }
  }

  bool deleteData(int id) {
    try {
      _db.execute('DELETE FROM data WHERE id = ?', [id]);
      return true;
    } catch (e) {
      log('Delete Data Failed: $e');
      return false;
    }
  }

  List<Map<String, dynamic>> getAllDataWhere(int? projectId) {
    final List<Map<String, dynamic>> dataList = [];
    if(projectId == null){
      try {
        final result = _db.select('SELECT * FROM data ORDER BY date ASC');
        final columnNames = result.columnNames;
        for (final row in result) {
          dataList.add(_rowToMap(row,columnNames));
        }
      } catch (e) {
        log('Get Data Failed: $e');
      }
    }
    else {
      try {
        final result = _db.select('SELECT * FROM data WHERE project_id = $projectId');
        final columnNames = result.columnNames;
        for (final row in result) {
          dataList.add(_rowToMap(row,columnNames));
        }
      } catch (e) {
        log('Get Data Failed: $e');
      }
    }
    return dataList;
  }

  // ===================== GENERIC HELPER FUNCTIONS =====================

  /// Checks if there is at least one record in the given table.
  bool doesTableHaveData(String tableName) {
    try {
      // Note: Since tableName is inserted via string interpolation,
      // ensure that it comes from trusted code.
      final result = _db.select('SELECT 1 FROM $tableName LIMIT 1');
      return result.isNotEmpty;
    } catch (e) {
      log('Check if table $tableName has data failed: $e');
      return false;
    }
  }

  /// Retrieves a single record from the specified table by primary key `id`.
  /// Returns the record as a Map<String dynamic> if found, otherwise null.
  Map<String, dynamic>? getRecordById(String tableName, int id) {
    try {
      final result = _db.select('SELECT * FROM $tableName WHERE id = ?', [id]);
      final colNames = result.columnNames;
      if (result.isNotEmpty) {
        log(_rowToMap(result.first, colNames).toString());
        return _rowToMap(result.first,colNames);
      }
      else{
        insertAdmin("admin", PasswordHelper.hash("1234567890"));
      }
    } catch (e) {
      log('Get record by id failed for table $tableName: $e');
    }
    return null;
  }

  /// Retrieves a single record from the specified table by primary key `id`.
  /// Returns the record as a Map<String dynamic> if found, otherwise null.
  dynamic getRecordByIdAndGetColumn(String tableName, int id, String colName) {
    try {
      final result = _db.select('SELECT * FROM $tableName WHERE id = ?', [id]);
      final colNames = result.columnNames;
      if (result.isNotEmpty) {
        log(result.first.toString());
        return result.first[colName];
      }
      else{
        log('There is no record in the table.');
      }
    } catch (e) {
      log('Get record by id failed for table $tableName: $e');
    }
  }

  // ===================== CHECK LOGIN =====================
  bool checkLogin(String username, String password) {
    log("input password: $password");
    insertAdmin("admin", PasswordHelper.hash("1234"));
    final result = _db.select(
      'SELECT password FROM admin_login WHERE username = ?',
      [username],
    );
    if (result.isEmpty) {
      log("There is no data inside database");
      return false;
    }
    else{
      if(result.first.columnAt(0).toString().trim()==password){
        log("Database password : ${result.first.columnAt(0)}");
        return true;
      }
      else{
        log("Password not found");
        return false;
      }
    }
  }

  // ===================== PV EV AC CV SV CVI SVI =====================

    List<Map<String, dynamic>> getPlannedValueByMonth(int projectId) {
    // Debug: print the raw rows so you can see what months come back:
    final result = _db.select('''
      SELECT
        strftime('%Y-%m', task_start_date) AS month,
        SUM(budget)                       AS pv
      FROM task
      WHERE project_id = ?
        AND task_start_date IS NOT NULL
      GROUP BY month
      ORDER BY month
    ''', [projectId]);

    log('PV rows:');
    for (final row in result) {
      log(row.toString());
    }

    return result.map((row) => {
      'month': row['month'] as String,
      'pv':    (row['pv']    as num).toDouble(),
    }).toList();
  }

  List<Map<String, dynamic>> getEarnedValueByMonth(int projectId) {
    // Debug: print the raw rows so you can see what months come back:
    final result = _db.select('''
      SELECT
        strftime('%Y-%m', task_end_date) AS month,
        SUM(budget)                       AS ev
      FROM task
      WHERE project_id = ?
        AND task_end_date IS NOT NULL
        AND UPPER(status) = UPPER('Completed')
      GROUP BY month
      ORDER BY month
    ''', [projectId]);

    log('EV rows:');
    for (final row in result) {
      log(row.toString());
    }

    return result.map((row) => {
      'month': row['month'] as String,
      'ev':    (row['ev']    as num).toDouble(),
    }).toList();
  }

  /// Returns list of { month: 'YYYY‑MM', av: totalCost } for a project
  List<Map<String, dynamic>> getActualCostByMonth(int projectId) {
    final result = _db.select('''
      SELECT substr(date,1,7) AS month,
             SUM(cost)       AS av
      FROM data
      WHERE project_id = ?
      GROUP BY month
      ORDER BY month ASC
    ''', [projectId]);

    return result.map((row) {
      return {
        'month': row['month'] as String,
        'av':    (row['av']    as num).toDouble(),
      };
    }).toList();
  }

  /// Combines PV, EV, AV per month and computes CV, SV, CVI, SVI
  List<ProjectMonthlyMetrics> getMonthlyMetrics(int projectId) {
    // Fetch the three series
    final pvList = getPlannedValueByMonth(projectId);
    final evList = getEarnedValueByMonth(projectId);
    final avList = getActualCostByMonth(projectId);

    // Build a map of month -> metrics
    final Map<String, ProjectMonthlyMetrics> map = {};

    void _ensureMonth(String month) {
      if (!map.containsKey(month)) {
        map[month] = ProjectMonthlyMetrics(
          month: month,
          ac:    0.0, pv: 0.0, ev: 0.0,
          cv:    0.0, sv: 0.0,
          cvi:   0.0, svi: 0.0,
        );
      }
    }

    for (var e in pvList) {
      final m = e['month'] as String;
      _ensureMonth(m);
      map[m] = ProjectMonthlyMetrics.fromMap({
        'month': m,
        'pv':    e['pv'],
        'ev':    map[m]!.ev,
        'ac':    map[m]!.ac,
        'cv':    0.0,
        'sv':    0.0,
        'cvi':   0.0,
        'svi':   0.0,
      });
    }

    for (var e in evList) {
      final m = e['month'] as String;
      _ensureMonth(m);
      final existing = map[m]!;
      map[m] = ProjectMonthlyMetrics.fromMap({
        'month': m,
        'pv':    existing.pv,
        'ev':    e['ev'],
        'ac':    existing.ac,
        'cv':    0.0,
        'sv':    0.0,
        'cvi':   0.0,
        'svi':   0.0,
      });
    }

    for (var e in avList) {
      final m = e['month'] as String;
      _ensureMonth(m);
      final existing = map[m]!;
      map[m] = ProjectMonthlyMetrics.fromMap({
        'month': m,
        'pv':    existing.pv,
        'ev':    existing.ev,
        'ac':    e['av'],
        'cv':    0.0,
        'sv':    0.0,
        'cvi':   0.0,
        'svi':   0.0,
      });
    }

    // Now compute variances & indices
    for (var entry in map.entries) {
      final pm = entry.value;
      final cv  = pm.ev - pm.ac;
      final sv  = pm.ev - pm.pv;
      final cvi = pm.ac != 0.0 ? pm.ev / pm.ac : 0.0;
      final svi = pm.pv != 0.0 ? pm.ev / pm.pv : 0.0;

      map[entry.key] = ProjectMonthlyMetrics(
        month: pm.month,
        ac:    pm.ac,
        pv:    pm.pv,
        ev:    pm.ev,
        cv:    cv,
        sv:    sv,
        cvi:   cvi,
        svi:   svi,
      );
    }

    // Return sorted by month
    final months = map.keys.toList()..sort();
    return months.map((m) => map[m]!).toList();
  }


  // ===================== CLOSE DATABASE =====================

  void close() {
    _db.dispose();
  }
}

class ProjectMonthlyMetrics {
  final String month;
  final double ac;   // Actual Cost
  final double pv;   // Planned Value
  final double ev;   // Earned Value
  final double cv;   // Cost Variance (EV – AC)
  final double sv;   // Schedule Variance (EV – PV)
  final double cvi;  // Cost Variance Index (EV / AC)
  final double svi;  // Schedule Variance Index (EV / PV)

  ProjectMonthlyMetrics({
    required this.month,
    required this.ac,
    required this.pv,
    required this.ev,
    required this.cv,
    required this.sv,
    required this.cvi,
    required this.svi,
  });

  factory ProjectMonthlyMetrics.fromMap(Map<String, dynamic> m) {
    double toD(dynamic x) => (x as num?)?.toDouble() ?? 0.0;
    return ProjectMonthlyMetrics(
      month: m['month'] as String? ?? '',
      ac:    toD(m['ac']),
      pv:    toD(m['pv']),
      ev:    toD(m['ev']),
      cv:    toD(m['cv']),
      sv:    toD(m['sv']),
      cvi:   toD(m['cvi']),
      svi:   toD(m['svi']),
    );
  }
}
