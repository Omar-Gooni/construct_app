import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class UserManagementPage extends StatefulWidget {
  final String role;
  const UserManagementPage({super.key, required this.role});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List allUsers = [];
  List displayedUsers = [];
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String selectedRole = 'user';
  final searchController = TextEditingController();
  bool isAscending = true;
  int? sortColumnIndex;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final response = await http.get(Uri.parse('http://172.20.10.4/flutter_api/get_users.php'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          allUsers = data['users'] ?? [];
          displayedUsers = allUsers;
        });
      }
    }
  }

  void searchUsers(String keyword) {
    final query = keyword.toLowerCase();
    final results = allUsers.where((user) {
      final email = user['email']?.toString().toLowerCase() ?? '';
      final role = user['role']?.toString().toLowerCase() ?? '';
      return email.contains(query) || role.contains(query);
    }).toList();

    setState(() {
      displayedUsers = results;
    });
  }

  Future<void> addUser() async {
    await http.post(
      Uri.parse('http://172.20.10.4/flutter_api/add_user.php'),
      body: {
        'email': emailController.text,
        'password': passwordController.text,
        'role': selectedRole,
      },
    );
    emailController.clear();
    passwordController.clear();
    Navigator.pop(context);
    fetchUsers();
  }

  Future<void> updateUser(String id) async {
    await http.post(
      Uri.parse('http://172.20.10.4/flutter_api/update_user.php'),
      body: {
        'id': id,
        'email': emailController.text,
        'password': passwordController.text,
        'role': selectedRole,
      },
    );
    emailController.clear();
    passwordController.clear();
    Navigator.pop(context);
    fetchUsers();
  }

  Future<void> deleteUser(String id) async {
    await http.post(
      Uri.parse('http://172.20.10.4/flutter_api/delete_user.php'),
      body: {'id': id},
    );
    fetchUsers();
  }

  void openAddDialog() {
    emailController.clear();
    passwordController.clear();
    selectedRole = 'user';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: 'Password')),
            DropdownButtonFormField<String>(
              value: selectedRole,
              items: ['admin', 'user']
                  .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                  .toList(),
              onChanged: (value) => setState(() => selectedRole = value!),
              decoration: InputDecoration(labelText: 'Role'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(onPressed: addUser, child: Text('Add')),
        ],
      ),
    );
  }

  void openEditDialog(Map user) {
    emailController.text = user['email'] ?? '';
    passwordController.text = user['password'] ?? '';
    selectedRole = user['role'] ?? 'user';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: 'Password')),
            DropdownButtonFormField<String>(
              value: selectedRole,
              items: ['admin', 'user']
                  .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                  .toList(),
              onChanged: (value) => setState(() => selectedRole = value!),
              decoration: InputDecoration(labelText: 'Role'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(onPressed: () => updateUser(user['id'].toString()), child: Text('Update')),
        ],
      ),
    );
  }

  void openSearchDialog() {
    searchController.clear();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Search Users'),
        content: TextField(
          controller: searchController,
          autofocus: true,
          decoration: InputDecoration(hintText: 'Enter keyword...'),
          onChanged: searchUsers,
        ),
        actions: [
          TextButton(
            onPressed: () {
              searchController.clear();
              setState(() {
                displayedUsers = allUsers;
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
          displayedUsers.sort((a, b) => compare(a['id'] ?? '', b['id'] ?? ''));
          break;
        case 1:
          displayedUsers.sort((a, b) => compare(a['email'] ?? '', b['email'] ?? ''));
          break;
        case 2:
          displayedUsers.sort((a, b) => compare(a['password'] ?? '', b['password'] ?? ''));
          break;
        case 3:
          displayedUsers.sort((a, b) => compare(a['role'] ?? '', b['role'] ?? ''));
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
              pw.Text('CIGAL CONSTRUCT – Users Report', style: pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['ID', 'Email', 'Password', 'Role'],
                data: displayedUsers.map((user) {
                  return [
                    user['id']?.toString() ?? '',
                    user['email'] ?? '',
                    user['password'] ?? '',
                    user['role'] ?? '',
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
        title: Text('Users'),
        actions: [
          IconButton(icon: Icon(Icons.picture_as_pdf), onPressed: exportToPdf),
          IconButton(icon: Icon(Icons.search), onPressed: openSearchDialog),
          if (widget.role == 'admin') IconButton(icon: Icon(Icons.add), onPressed: openAddDialog),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: displayedUsers.isEmpty
            ? Center(child: Text('No users found'))
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  sortColumnIndex: sortColumnIndex,
                  sortAscending: isAscending,
                  columns: [
                    DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold)), onSort: onSort),
                    DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold)), onSort: onSort),
                    DataColumn(label: Text('Password', style: TextStyle(fontWeight: FontWeight.bold)), onSort: onSort),
                    DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold)), onSort: onSort),
                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: displayedUsers.map((user) {
                    return DataRow(cells: [
                      DataCell(Text(user['id']?.toString() ?? '')),
                      DataCell(Text(user['email'] ?? '')),
                      DataCell(Text(user['password'] ?? '')),
                      DataCell(Text(user['role'] ?? '')),
                      DataCell(Row(
                        children: [
                          if (widget.role == 'admin')
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => openEditDialog(user),
                            ),
                          if (widget.role == 'admin')
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteUser(user['id'].toString()),
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
