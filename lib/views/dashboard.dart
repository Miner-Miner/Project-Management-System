import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pms/util/database_util.dart';
import 'package:pie_chart/pie_chart.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Map<String, dynamic>> _projects = [];
  int? _selectedProjectId = -1;

  Map<String, double> _pieData = {};
  Map<String, int> _taskStats = {};
  List<Map<String, dynamic>> _ganttData = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final projects = DatabaseHelper().getAllProjects();
    setState(() => _projects = projects);
  }

  Future<void> _onProjectSelected(String? projectName) async {
    // if (projectName == null) return;
    // final sel = _projects.firstWhere(
    //   (p) => p['project_name'] == projectName,
    //   orElse: () => {},
    // );
    // if (sel.isEmpty) return;

    // final projectId = sel['id'] as int;
    // final pieData = await _getPieChartData(projectId);
    // final taskStats = await _getTaskCompletionGraph(projectId);
    // final ganttData = await _getGanttData(projectId);

    // setState(() {
    //   _selectedProjectId = projectId;
    //   _pieData = pieData;
    //   _taskStats = taskStats;
    //   _ganttData = ganttData;
    // });
  }

  Future<Map<String, double>> _getPieChartData(int projectId) async {
    final rows = await DatabaseHelper().getProjectDataByProject(projectId);
    final Map<String, double> data = {};
    for (var r in rows) {
      final desc = (r['description'] as String?)?.trim().isNotEmpty == true
          ? r['description'] as String
          : 'Other';
      final cost = (r['cost'] as num?)?.toDouble() ?? 0.0;
      data[desc] = (data[desc] ?? 0) + cost;
    }
    return data;
  }

  /// 1. Count tasks by status (pending, doing, done, complete)
  Future<Map<String, int>> _getTaskCompletionGraph(int projectId) async {
    final rows = await DatabaseHelper().getTasksByProject(projectId);

    // Initialize counts for each status (capitalized for friendly labels)
    final Map<String, int> stats = {
      'Pending': 0,
      'Doing': 0,
      'Done': 0,
      'Complete': 0,
    };

    for (var t in rows) {
      // Log raw status for debugging
      log('Task status: "${t['status']}"');

      final rawStatus = (t['status'] as String?)?.trim();
      if (rawStatus == null || rawStatus.isEmpty) {
        stats['Pending'] = stats['Pending']! + 1;
      } else {
        final formatted = rawStatus.toLowerCase();
        final key = formatted[0].toUpperCase() + formatted.substring(1);
        if (stats.containsKey(key)) {
          stats[key] = stats[key]! + 1;
        } else {
          // in case you get an unexpected status
          stats[key] = 1;
        }
      }
    }

    return stats;
  }

  /// 2. New helper to pick a color per status
  Color _colorForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'doing':
        return Colors.blueAccent;
      case 'done':
        return Colors.green;
      case 'complete':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  /// 3. Updated bar chart builder to use the status‑counts + colors
  Widget _buildBarChart() {
    if (_taskStats.isEmpty) return Center(child: Text('No tasks to display'));

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxCount =
            _taskStats.values.fold<int>(0, (p, v) => v > p ? v : p);
        final availableHeight = constraints.maxHeight - 48;
        final factor = maxCount > 0 ? availableHeight / maxCount : 0;
        const barWidth = 40.0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: _taskStats.entries.map((e) {
            final barHeight = e.value * factor;
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${e.value}',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Container(
                  width: barWidth,
                  height: barHeight.toDouble(),
                  color: _colorForStatus(e.key),
                ),
                SizedBox(height: 4),
                Text(e.key),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getGanttData(int projectId) async {
    final rows = await DatabaseHelper().getTasksByProject(projectId);
    return rows.map((t) {
      final start = DateTime.tryParse(
              t['task_start_date'] as String? ?? '') ??
          DateTime.now();
      final end = DateTime.tryParse(
              t['task_end_date'] as String? ?? '') ??
          start;
      final title = (t['task_title'] as String?) ?? '';
      final priority = (t['priority'] as String?) ?? 'Unknown';
      return {
        'title': title,
        'start': start,
        'end': end,
        'priority': priority,
      };
    }).toList();
  }

  Color _colorForPriority(String p) {
    switch (p.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blueAccent;
    }
  }

  Widget _buildPieChart() {
    if (_pieData.isEmpty) return Center(child: Text('No data to display'));
    return PieChart(
      dataMap: _pieData,
      chartType: ChartType.ring,
      animationDuration: Duration(milliseconds: 800),
      chartLegendSpacing: 32,
      chartRadius: MediaQuery.of(context).size.width / 3,
      legendOptions: LegendOptions(
        showLegendsInRow: false,
        legendPosition: LegendPosition.right,
        showLegends: true,
        legendTextStyle: TextStyle(fontWeight: FontWeight.bold),
      ),
      chartValuesOptions: ChartValuesOptions(
        showChartValuesInPercentage: true,
        showChartValuesOutside: true,
      ),
    );
  }

  Widget _buildPriorityLegend() {
    final setP = _ganttData.map((t) => t['priority'] as String).toSet();
    if (setP.isEmpty) return SizedBox.shrink();
    return Row(
      children: setP.map((p) {
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            children: [
              Container(width: 12, height: 12, color: _colorForPriority(p)),
              SizedBox(width: 4),
              Text(p, style: TextStyle(fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Now scrollable both vertically and horizontally
  Widget _buildGanttChart() {
    if (_ganttData.isEmpty) return Center(child: Text('No tasks to display'));

    final tasks = _ganttData.map((t) {
      return {
        'title': t['title'] as String,
        'start': t['start'] as DateTime,
        'end': t['end'] as DateTime,
        'priority': t['priority'] as String,
      };
    }).toList();

    final allDates = tasks
        .expand((t) => [t['start'] as DateTime, t['end'] as DateTime])
        .toList();
    final minD = allDates.reduce((a, b) => a.isBefore(b) ? a : b);
    final maxD = allDates.reduce((a, b) => a.isAfter(b) ? a : b);
    final days = maxD.difference(minD).inDays + 1;
    const dayW = 60.0; // width per day

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPriorityLegend(),
          SizedBox(height: 8),

          // Both‐axis scrollable area
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date header
                Row(
                  children: List.generate(days, (i) {
                    final d = minD.add(Duration(days: i));
                    return Container(
                      width: dayW,
                      alignment: Alignment.center,
                      child: Text(
                        DateFormat('MMM d').format(d),
                        style: TextStyle(fontSize: 12),
                      ),
                    );
                  }),
                ),
                SizedBox(height: 4),

                // Task bars
                ...tasks.map((t) {
                  final start = t['start'] as DateTime;
                  final end = t['end'] as DateTime;
                  final title = t['title'] as String;
                  final priority = t['priority'] as String;
                  final offset = start.difference(minD).inDays;
                  final length = end.difference(start).inDays + 1;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(width: offset * dayW),
                        Container(
                          width: length * dayW,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _colorForPriority(priority),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            title,
                            style: TextStyle(color: Colors.white, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedName = _selectedProjectId == null
        ? null
        : (_projects.firstWhere((p) => p['id'] == _selectedProjectId,
            orElse: () => {})['project_name'] as String?);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project Dropdown
          DropdownButtonFormField<String>(
            value: selectedName,
            hint: Text('Select Project'),
            items: _projects.map((p) {
              return DropdownMenuItem(
                value: p['project_name'] as String,
                child: Text(p['project_name'] as String),
              );
            }).toList(),
            onChanged: _onProjectSelected,
            decoration: InputDecoration(
              labelText: 'Select Project',
              border: OutlineInputBorder(),
            ),
          ),

          SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DashboardProjectDataPage(_selectedProjectId!),
                ),
              );
            },
            child: Text('Project Progress (Cost Breakdown)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DashboardProjectDataPage(_selectedProjectId!),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildPieChart(),
            ),
          ),

          SizedBox(height: 20),
          Text('Task Completion',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Container(
            height: 200,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildBarChart(),
          ),

          SizedBox(height: 20),
          Text('Project Timeline (Gantt Chart)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Container(
            height: 400,
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildGanttChart(),
          ),
        ],
      ),
    );
  }
}

class DashboardProjectDataPage extends StatefulWidget {
  final int id;
  DashboardProjectDataPage(this.id);

  @override
  _DashboardProjectDataPageState createState() => _DashboardProjectDataPageState(id);
}

class _DashboardProjectDataPageState extends State<DashboardProjectDataPage> {
  final int id;
  _DashboardProjectDataPageState(this.id);

  List<ProjectMonthlyMetrics> performanceData = [];

  @override
  void initState() {
    super.initState();
    performanceData = DatabaseHelper().getMonthlyMetrics(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Project Performance')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).height,
          child: (performanceData.isEmpty || id == -1)
              ? Center(child: Text('No data'))
              : SizedBox(
                  width: MediaQuery.sizeOf(context).width,
                  height: MediaQuery.sizeOf(context).height,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Month')),
                        DataColumn(label: Text('AC')),
                        DataColumn(label: Text('PV')),
                        DataColumn(label: Text('EV')),
                        DataColumn(label: Text('CV')),
                        DataColumn(label: Text('SV')),
                        DataColumn(label: Text('CVI')),
                        DataColumn(label: Text('SVI')),
                      ],
                      rows: performanceData.map((m) {
                        return DataRow(cells: [
                          DataCell(Text(m.month)),
                          DataCell(Text(m.ac.toStringAsFixed(2)+" MMK")),
                          DataCell(Text(m.pv.toStringAsFixed(2)+" MMK")),
                          DataCell(Text(m.ev.toStringAsFixed(2)+" MMK")),
                          DataCell(Text(m.cv.toStringAsFixed(2)+" MMK")),
                          DataCell(Text(m.sv.toStringAsFixed(2)+" MMK")),
                          DataCell(Text((m.cvi*100.00).toStringAsFixed(2)+" %")),
                          DataCell(Text((m.svi*100.00).toStringAsFixed(2)+" %")),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
