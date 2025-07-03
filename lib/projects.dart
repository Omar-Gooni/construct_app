import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ProjectsPage extends StatefulWidget {
  final String role;

  const ProjectsPage({super.key, required this.role});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  List allProjects = [];
  List displayedProjects = [];
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final searchController = TextEditingController();
  bool isAscending = true;
  int? sortColumnIndex;

  @override
  void initState() {
    super.initState();
    fetchProjects();
  }

  Future<void> fetchProjects() async {
    final response = await http.get(Uri.parse('http://172.20.10.4/flutter_api/get_projects.php'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          allProjects = data['projects'];
          displayedProjects = allProjects;
        });
      }
    }
  }

  void searchProjects(String keyword) {
    final query = keyword.toLowerCase();
    final results = allProjects.where((project) {
      final name = project['name'].toString().toLowerCase();
      final desc = project['description'].toString().toLowerCase();
      return name.contains(query) || desc.contains(query);
    }).toList();

    setState(() {
      displayedProjects = results;
    });
  }

  Future<void> addProject() async {
    await http.post(
      Uri.parse('http://172.20.10.4/flutter_api/add_project.php'),
      body: {
        'name': nameController.text,
        'description': descController.text,
      },
    );
    nameController.clear();
    descController.clear();
    Navigator.pop(context);
    fetchProjects();
  }

  Future<void> updateProject(String id) async {
    await http.post(
      Uri.parse('http://172.20.10.4/flutter_api/update_project.php'),
      body: {
        'id': id,
        'name': nameController.text,
        'description': descController.text,
      },
    );
    nameController.clear();
    descController.clear();
    Navigator.pop(context);
    fetchProjects();
  }

  Future<void> deleteProject(String id) async {
    await http.post(
      Uri.parse('http://172.20.10.4/flutter_api/delete_project.php'),
      body: {'id': id},
    );
    fetchProjects();
  }

  void openAddDialog() {
    nameController.clear();
    descController.clear();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Project Name')),
            TextField(controller: descController, decoration: InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(onPressed: addProject, child: Text('Add')),
        ],
      ),
    );
  }

  void openEditDialog(Map project) {
    nameController.text = project['name'];
    descController.text = project['description'] ?? '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Project Name')),
            TextField(controller: descController, decoration: InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(onPressed: () => updateProject(project['id']), child: Text('Update')),
        ],
      ),
    );
  }

  void openSearchDialog() {
    searchController.clear();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Search Projects'),
        content: TextField(
          controller: searchController,
          autofocus: true,
          decoration: InputDecoration(hintText: 'Enter keyword...'),
          onChanged: searchProjects,
        ),
        actions: [
          TextButton(
            onPressed: () {
              searchController.clear();
              setState(() {
                displayedProjects = allProjects;
              });
              Navigator.pop(context);
            },
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void onSort(int index, bool asc) {
    final compare = (dynamic a, dynamic b) => asc ? a.compareTo(b) : b.compareTo(a);

    setState(() {
      sortColumnIndex = index;
      isAscending = asc;
      switch (index) {
        case 0:
          displayedProjects.sort((a, b) => compare(a['id'], b['id']));
          break;
        case 1:
          displayedProjects.sort((a, b) => compare(a['name'], b['name']));
          break;
        case 2:
          displayedProjects.sort((a, b) => compare(a['description'] ?? '', b['description'] ?? ''));
          break;
        case 3:
          displayedProjects.sort((a, b) => compare(a['created_at'], b['created_at']));
          break;
      }
    });
  }

  void exportToPdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text('CIGAL CONSTRUCT – Projects Report', style: pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['ID', 'Name', 'Description', 'Created'],
                data: displayedProjects.map((proj) {
                  return [
                    proj['id'].toString(),
                    proj['name'],
                    proj['description'] ?? '',
                    proj['created_at'],
                  ];
                }).toList(),
              )
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Projects'),
        actions: [
          IconButton(icon: Icon(Icons.picture_as_pdf), onPressed: exportToPdf),
          IconButton(icon: Icon(Icons.search), onPressed: openSearchDialog),
          if (widget.role == 'admin') IconButton(icon: Icon(Icons.add), onPressed: openAddDialog),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: displayedProjects.isEmpty
            ? Center(child: Text('No projects found'))
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  sortColumnIndex: sortColumnIndex,
                  sortAscending: isAscending,
                  columns: [
                    DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold)), onSort: onSort),
                    DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)), onSort: onSort),
                    DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold)), onSort: onSort),
                    DataColumn(label: Text('Created', style: TextStyle(fontWeight: FontWeight.bold)), onSort: onSort),
                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: displayedProjects.map((project) {
                    return DataRow(cells: [
                      DataCell(Text(project['id'].toString())),
                      DataCell(Text(project['name'])),
                      DataCell(Text(project['description'] ?? '')),
                      DataCell(Text(project['created_at'])),
                      DataCell(Row(
                        children: [
                          if (widget.role == 'admin')
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => openEditDialog(project),
                            ),
                          if (widget.role == 'admin')
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteProject(project['id']),
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
