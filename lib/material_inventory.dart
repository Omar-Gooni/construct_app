import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MaterialInventoryPage extends StatefulWidget {
  final String role;
  const MaterialInventoryPage({super.key, required this.role});

  @override
  State<MaterialInventoryPage> createState() => _MaterialInventoryPageState();
}

class _MaterialInventoryPageState extends State<MaterialInventoryPage> {
  List allMaterials = [];
  List displayedMaterials = [];
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final quantityController = TextEditingController();
  final unitController = TextEditingController();
  String status = 'available';
  final searchController = TextEditingController();
  bool isAscending = true;
  int? sortColumnIndex;

  @override
  void initState() {
    super.initState();
    fetchMaterials();
  }

  Future<void> fetchMaterials() async {
    final response = await http.get(Uri.parse('http://172.20.10.4/flutter_api/get_materials.php'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          allMaterials = data['materials'] ?? [];
          displayedMaterials = allMaterials;
        });
      }
    }
  }

  void searchMaterials(String keyword) {
    final query = keyword.toLowerCase();
    final results = allMaterials.where((m) {
      return (m['material_name'] ?? '').toLowerCase().contains(query);
    }).toList();

    setState(() {
      displayedMaterials = results;
    });
  }

  Future<void> addMaterial() async {
    await http.post(
      Uri.parse('http://172.20.10.4/flutter_api/add_material.php'),
      body: {
        'material_name': nameController.text,
        'description': descController.text,
        'quantity': quantityController.text,
        'unit': unitController.text,
        'status': status
      },
    );
    Navigator.pop(context);
    fetchMaterials();
  }

  Future<void> updateMaterial(String id) async {
    await http.post(
      Uri.parse('http://172.20.10.4/flutter_api/update_material.php'),
      body: {
        'id': id,
        'material_name': nameController.text,
        'description': descController.text,
        'quantity': quantityController.text,
        'unit': unitController.text,
        'status': status
      },
    );
    Navigator.pop(context);
    fetchMaterials();
  }

  Future<void> deleteMaterial(String id) async {
    await http.post(
      Uri.parse('http://172.20.10.4/flutter_api/delete_material.php'),
      body: {'id': id},
    );
    fetchMaterials();
  }

  void openAddDialog() {
    nameController.clear();
    descController.clear();
    quantityController.clear();
    unitController.clear();
    status = 'available';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Material'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: 'Material Name')),
              TextField(controller: descController, decoration: InputDecoration(labelText: 'Description')),
              TextField(controller: quantityController, decoration: InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
              TextField(controller: unitController, decoration: InputDecoration(labelText: 'Unit')),
              DropdownButtonFormField<String>(
                value: status,
                items: ['available', 'unavailable']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) => setState(() => status = value!),
                decoration: InputDecoration(labelText: 'Status'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(onPressed: addMaterial, child: Text('Add')),
        ],
      ),
    );
  }

  void openEditDialog(Map m) {
    nameController.text = m['material_name'] ?? '';
    descController.text = m['description'] ?? '';
    quantityController.text = m['quantity'] ?? '';
    unitController.text = m['unit'] ?? '';
    status = m['status'] ?? 'available';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Material'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: 'Material Name')),
              TextField(controller: descController, decoration: InputDecoration(labelText: 'Description')),
              TextField(controller: quantityController, decoration: InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
              TextField(controller: unitController, decoration: InputDecoration(labelText: 'Unit')),
              DropdownButtonFormField<String>(
                value: status,
                items: ['available', 'unavailable']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) => setState(() => status = value!),
                decoration: InputDecoration(labelText: 'Status'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(onPressed: () => updateMaterial(m['id'].toString()), child: Text('Update')),
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
            pw.Text('CIGAL CONSTRUCT – Material Inventory', style: pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['ID', 'Name', 'Description', 'Qty', 'Unit', 'Status'],
              data: displayedMaterials.map((m) => [
                m['id'],
                m['material_name'],
                m['description'],
                m['quantity'],
                m['unit'],
                m['status'],
              ]).toList(),
            ),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Material Inventory'),
        actions: [
          IconButton(icon: Icon(Icons.picture_as_pdf), onPressed: exportToPdf),
          IconButton(icon: Icon(Icons.search), onPressed: () {
            searchController.clear();
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('Search Materials'),
                content: TextField(
                  controller: searchController,
                  onChanged: searchMaterials,
                  decoration: InputDecoration(hintText: 'Enter material name...'),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
                ],
              ),
            );
          }),
          if (widget.role == 'admin') IconButton(icon: Icon(Icons.add), onPressed: openAddDialog),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: displayedMaterials.isEmpty
            ? Center(child: Text('No materials found'))
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  sortColumnIndex: sortColumnIndex,
                  sortAscending: isAscending,
                  columns: [
                    DataColumn(label: Text('ID')), 
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Desc')),
                    DataColumn(label: Text('Qty')),
                    DataColumn(label: Text('Unit')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: displayedMaterials.map((m) => DataRow(cells: [
                    DataCell(Text(m['id'].toString())),
                    DataCell(Text(m['material_name'] ?? '')),
                    DataCell(Text(m['description'] ?? '')),
                    DataCell(Text(m['quantity'].toString())),
                    DataCell(Text(m['unit'] ?? '')),
                    DataCell(Text(m['status'] ?? '')),
                    DataCell(Row(children: [
                      if (widget.role == 'admin')
                        IconButton(icon: Icon(Icons.edit, color: Colors.blue), onPressed: () => openEditDialog(m)),
                      if (widget.role == 'admin')
                        IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => deleteMaterial(m['id'].toString())),
                    ])),
                  ])).toList(),
                ),
              ),
      ),
    );
  }
}
