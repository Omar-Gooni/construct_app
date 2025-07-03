import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TasksPage extends StatefulWidget {
  final String role;
  const TasksPage({super.key, required this.role});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  List allTasks = [];
  List displayedTasks = [];
  List projectsList = [];
  List workersList = [];

  final descController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  String status = 'Pending';
  int? selectedProjectId;
  int? selectedWorkerId;

  bool isAscending = true;
  int? sortColumnIndex;

  @override
  void initState() {
    super.initState();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    await Future.wait([fetchTasks(), fetchProjects(), fetchWorkers()]);
  }

  Future<void> fetchTasks() async {
    final res = await http.get(Uri.parse('http://172.20.10.4/flutter_api/get_tasks.php'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['success']) {
        setState(() {
          allTasks = data['tasks'];
          displayedTasks = allTasks;
        });
      }
    }
  }

  Future<void> fetchProjects() async {
    final res = await http.get(Uri.parse('http://172.20.10.4/flutter_api/get_projects_dropdown.php'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['success']) {
        setState(() => projectsList = data['projects']);
      }
    }
  }

  Future<void> fetchWorkers() async {
    final res = await http.get(Uri.parse('http://172.20.10.4/flutter_api/get_workers_dropdown.php'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['success']) {
        setState(() => workersList = data['workers']);
      }
    }
  }

  Future<void> addTask() async {
    await http.post(Uri.parse('http://172.20.10.4/flutter_api/add_task.php'), body: {
      'project_id': selectedProjectId.toString(),
      'worker_id': selectedWorkerId.toString(),
      'description': descController.text,
      'start_date': startDate.toString().split(' ')[0],
      'end_date': endDate.toString().split(' ')[0],
      'status': status,
    });
    Navigator.pop(context);
    fetchTasks();
  }

  Future<void> updateTask(String id) async {
    await http.post(Uri.parse('http://172.20.10.4/flutter_api/update_task.php'), body: {
      'id': id,
      'project_id': selectedProjectId.toString(),
      'worker_id': selectedWorkerId.toString(),
      'description': descController.text,
      'start_date': startDate.toString().split(' ')[0],
      'end_date': endDate.toString().split(' ')[0],
      'status': status,
    });
    Navigator.pop(context);
    fetchTasks();
  }

  Future<void> deleteTask(String id) async {
    await http.post(Uri.parse('http://172.20.10.4/flutter_api/delete_task.php'), body: {'id': id});
    fetchTasks();
  }

  void openAddDialog() {
    descController.clear();
    startDate = null;
    endDate = null;
    status = 'Pending';
    selectedProjectId = null;
    selectedWorkerId = null;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Task'),
        content: taskForm(() => addTask()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(onPressed: addTask, child: Text('Add')),
        ],
      ),
    );
  }

  void openEditDialog(Map task) {
    final matchedProject = projectsList.firstWhere(
      (p) => p['name'] == task['project_name'],
      orElse: () => null,
    );
    final matchedWorker = workersList.firstWhere(
      (w) => w['name'] == task['worker_name'],
      orElse: () => null,
    );

    if (matchedProject == null || matchedWorker == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Project or worker not found in dropdown list.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    selectedProjectId = int.tryParse(matchedProject['id'].toString());
    selectedWorkerId = int.tryParse(matchedWorker['id'].toString());
    descController.text = task['description'] ?? '';
    startDate = DateTime.tryParse(task['start_date']);
    endDate = DateTime.tryParse(task['end_date']);
    status = task['status'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Task'),
        content: taskForm(() => updateTask(task['id'].toString())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(onPressed: () => updateTask(task['id'].toString()), child: Text('Update')),
        ],
      ),
    );
  }

  Widget taskForm(VoidCallback onSubmit) {
    return SingleChildScrollView(
      child: Column(
        children: [
          DropdownButtonFormField(
            value: selectedProjectId,
            items: projectsList.map((proj) => DropdownMenuItem(
              value: int.tryParse(proj['id'].toString()),
              child: Text(proj['name']),
            )).toList(),
            onChanged: (val) => selectedProjectId = val as int?,
            decoration: InputDecoration(labelText: 'Project'),
          ),
          DropdownButtonFormField(
            value: selectedWorkerId,
            items: workersList.map((w) => DropdownMenuItem(
              value: int.tryParse(w['id'].toString()),
              child: Text(w['name']),
            )).toList(),
            onChanged: (val) => selectedWorkerId = val as int?,
            decoration: InputDecoration(labelText: 'Worker'),
          ),
          TextField(controller: descController, decoration: InputDecoration(labelText: 'Description')),
          ListTile(
            title: Text('Start Date: ${startDate != null ? startDate.toString().split(' ')[0] : 'Select'}'),
            onTap: () async {
              startDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              setState(() {});
            },
          ),
          ListTile(
            title: Text('End Date: ${endDate != null ? endDate.toString().split(' ')[0] : 'Select'}'),
            onTap: () async {
              endDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              setState(() {});
            },
          ),
          DropdownButtonFormField(
            value: status,
            items: ['Pending', 'In Progress', 'Completed']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (val) => status = val!,
            decoration: InputDecoration(labelText: 'Status'),
          ),
        ],
      ),
    );
  }

  void exportToPdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          children: [
            pw.Text('CIGAL CONSTRUCT – Tasks Report', style: pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['ID', 'Project', 'Worker', 'Description', 'Start', 'End', 'Status'],
              data: displayedTasks.map((t) => [
                t['id'].toString(),
                t['project_name'],
                t['worker_name'],
                t['description'] ?? '',
                t['start_date'],
                t['end_date'],
                t['status'],
              ]).toList(),
            ),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void onSort(int index, bool asc) {
    final compare = (dynamic a, dynamic b) => asc ? a.compareTo(b) : b.compareTo(a);

    setState(() {
      sortColumnIndex = index;
      isAscending = asc;
      switch (index) {
        case 0:
          displayedTasks.sort((a, b) => compare(a['id'], b['id']));
          break;
        case 3:
          displayedTasks.sort((a, b) => compare(a['description'] ?? '', b['description'] ?? ''));
          break;
        case 6:
          displayedTasks.sort((a, b) => compare(a['status'], b['status']));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks'),
        actions: [
          IconButton(icon: Icon(Icons.picture_as_pdf), onPressed: exportToPdf),
          if (widget.role == 'admin') IconButton(icon: Icon(Icons.add), onPressed: openAddDialog),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: displayedTasks.isEmpty
            ? Center(child: Text('No tasks found'))
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  sortColumnIndex: sortColumnIndex,
                  sortAscending: isAscending,
                  columns: [
                    DataColumn(label: Text('ID'), onSort: onSort),
                    DataColumn(label: Text('Project')),
                    DataColumn(label: Text('Worker')),
                    DataColumn(label: Text('Description'), onSort: onSort),
                    DataColumn(label: Text('Start')),
                    DataColumn(label: Text('End')),
                    DataColumn(label: Text('Status'), onSort: onSort),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: displayedTasks.map((task) {
                    return DataRow(cells: [
                      DataCell(Text(task['id'].toString())),
                      DataCell(Text(task['project_name'])),
                      DataCell(Text(task['worker_name'])),
                      DataCell(Text(task['description'] ?? '')),
                      DataCell(Text(task['start_date'])),
                      DataCell(Text(task['end_date'])),
                      DataCell(Text(task['status'])),
                      DataCell(Row(
                        children: [
                          if (widget.role == 'admin')
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => openEditDialog(task),
                            ),
                          if (widget.role == 'admin')
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteTask(task['id']),
                            ),
                        ],
                      )),
                    ]);
                  }).toList(),
                ),
              ),
      ),
    );
  }
}
