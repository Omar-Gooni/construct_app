import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class WorkersPage extends StatefulWidget {
  final String role;

  const WorkersPage({super.key, required this.role});

  @override
  State<WorkersPage> createState() => _WorkersPageState();
}

class _WorkersPageState extends State<WorkersPage> {
  List allWorkers = [];
  List displayedWorkers = [];
  int? sortColumnIndex;
  bool isAscending = true;
  final searchController = TextEditingController();

  final nameController = TextEditingController();
  final positionController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchWorkers();
  }

  Future<void> fetchWorkers() async {
    final res = await http.get(Uri.parse('http://172.20.10.4/flutter_api/get_workers.php'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['success']) {
        setState(() {
          allWorkers = data['workers'];
          displayedWorkers = allWorkers;
        });
      }
    }
  }

  Future<void> addWorker() async {
    await http.post(
      Uri.parse('http://172.20.10.4/flutter_api/add_worker.php'),
      body: {
        'name': nameController.text,
        'position': positionController.text,
        'email': emailController.text,
        'phone': phoneController.text,
        'address': addressController.text,
      },
    );
    Navigator.pop(context);
    fetchWorkers();
  }

  Future<void> updateWorker(String id) async {
    await http.post(
      Uri.parse('http://172.20.10.4/flutter_api/update_worker.php'),
      body: {
        'id': id,
        'name': nameController.text,
        'position': positionController.text,
        'email': emailController.text,
        'phone': phoneController.text,
        'address': addressController.text,
      },
    );
    Navigator.pop(context);
    fetchWorkers();
  }

  Future<void> deleteWorker(String id) async {
    await http.post(
      Uri.parse('http://172.20.10.4/flutter_api/delete_worker.php'),
      body: {'id': id},
    );
    fetchWorkers();
  }

  void openAddDialog() {
    nameController.clear();
    positionController.clear();
    emailController.clear();
    phoneController.clear();
    addressController.clear();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Worker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name')),
            TextField(controller: positionController, decoration: InputDecoration(labelText: 'Position')),
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: phoneController, decoration: InputDecoration(labelText: 'Phone')),
            TextField(controller: addressController, decoration: InputDecoration(labelText: 'Address')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(onPressed: addWorker, child: Text('Add')),
        ],
      ),
    );
  }

  void openEditDialog(Map worker) {
    nameController.text = worker['name'];
    positionController.text = worker['position'];
    emailController.text = worker['email'];
    phoneController.text = worker['phone'];
    addressController.text = worker['address'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Worker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name')),
            TextField(controller: positionController, decoration: InputDecoration(labelText: 'Position')),
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: phoneController, decoration: InputDecoration(labelText: 'Phone')),
            TextField(controller: addressController, decoration: InputDecoration(labelText: 'Address')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(onPressed: () => updateWorker(worker['id']), child: Text('Update')),
        ],
      ),
    );
  }

  void searchWorkers(String keyword) {
    final query = keyword.toLowerCase();
    final results = allWorkers.where((worker) {
      final name = worker['name'].toLowerCase();
      final position = worker['position'].toLowerCase();
      return name.contains(query) || position.contains(query);
    }).toList();

    setState(() {
      displayedWorkers = results;
    });
  }

  void exportToPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          children: [
            pw.Text('CIGAL CONSTRUCT – Workers Report', style: pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Name', 'Position', 'Email', 'Phone', 'Address'],
              data: displayedWorkers.map((w) {
                return [
                  w['name'],
                  w['position'],
                  w['email'],
                  w['phone'],
                  w['address'],
                ];
              }).toList(),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void onSort(int columnIndex, bool ascending) {
    final compare = (dynamic a, dynamic b) => ascending ? a.compareTo(b) : b.compareTo(a);

    setState(() {
      sortColumnIndex = columnIndex;
      isAscending = ascending;

      switch (columnIndex) {
        case 0:
          displayedWorkers.sort((a, b) => compare(a['name'], b['name']));
          break;
        case 1:
          displayedWorkers.sort((a, b) => compare(a['position'], b['position']));
          break;
        case 2:
          displayedWorkers.sort((a, b) => compare(a['email'], b['email']));
          break;
        case 3:
          displayedWorkers.sort((a, b) => compare(a['phone'], b['phone']));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workers'),
        actions: [
          IconButton(icon: Icon(Icons.picture_as_pdf), onPressed: exportToPDF),
          IconButton(icon: Icon(Icons.search), onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('Search Workers'),
                content: TextField(
                  controller: searchController,
                  autofocus: true,
                  decoration: InputDecoration(hintText: 'Search name or position'),
                  onChanged: searchWorkers,
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      searchController.clear();
                      setState(() {
                        displayedWorkers = allWorkers;
                      });
                      Navigator.pop(context);
                    },
                    child: Text('Close'),
                  ),
                ],
              ),
            );
          }),
          if (widget.role == 'admin') IconButton(icon: Icon(Icons.add), onPressed: openAddDialog),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: displayedWorkers.isEmpty
            ? Center(child: Text('No workers found'))
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  sortColumnIndex: sortColumnIndex,
                  sortAscending: isAscending,
                  columns: [
                    DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)), onSort: onSort),
                    DataColumn(label: Text('Position', style: TextStyle(fontWeight: FontWeight.bold)), onSort: onSort),
                    DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold)), onSort: onSort),
                    DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold)), onSort: onSort),
                    DataColumn(label: Text('Address', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: displayedWorkers.map((worker) {
                    return DataRow(cells: [
                      DataCell(Text(worker['name'] ?? '')),
                      DataCell(Text(worker['position'] ?? '')),
                      DataCell(Text(worker['email'] ?? '')),
                      DataCell(Text(worker['phone'] ?? '')),
                      DataCell(Text(worker['address'] ?? '')),
                      DataCell(Row(
                        children: [
                          if (widget.role == 'admin')
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => openEditDialog(worker),
                            ),
                          if (widget.role == 'admin')
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteWorker(worker['id']),
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
