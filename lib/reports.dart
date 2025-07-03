// reports.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  DateTime? startDate;
  DateTime? endDate;
  List filteredTasks = [];

  Future<void> fetchFilteredTasks() async {
    if (startDate == null || endDate == null) return;

    final response = await http.get(Uri.parse(
      'http://172.20.10.4/flutter_api/get_tasks.php',
    ));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        final allTasks = data['tasks'];
        setState(() {
          filteredTasks = allTasks.where((task) {
            final taskDate = DateTime.tryParse(task['start_date'] ?? '') ?? DateTime(1900);
            return taskDate.isAfter(startDate!.subtract(Duration(days: 1))) &&
                   taskDate.isBefore(endDate!.add(Duration(days: 1)));
          }).toList();
        });
      }
    }
  }

  void exportToPdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          children: [
            pw.Text('CIGAL CONSTRUCT – Task Report', style: pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 10),
            pw.Text('From: ${startDate.toString().split(' ')[0]} To: ${endDate.toString().split(' ')[0]}'),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['ID', 'Project', 'Worker', 'Start', 'End', 'Status'],
              data: filteredTasks.map((task) => [
                task['id'].toString(),
                task['project_name'],
                task['worker_name'],
                task['start_date'],
                task['end_date'],
                task['status'],
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
        title: Text('Reports'),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: filteredTasks.isNotEmpty ? exportToPdf : null,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ListTile(
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
                ),
                Expanded(
                  child: ListTile(
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
                ),
                ElevatedButton(
                  onPressed: fetchFilteredTasks,
                  child: Text('Generate'),
                ),
              ],
            ),
            SizedBox(height: 20),
            filteredTasks.isEmpty
                ? Center(child: Text('No tasks found for selected range'))
                : Expanded(
                    child: ListView.builder(
                      itemCount: filteredTasks.length,
                      itemBuilder: (_, i) {
                        final task = filteredTasks[i];
                        return Card(
                          child: ListTile(
                            title: Text('${task['project_name']} - ${task['worker_name']}'),
                            subtitle: Text(
                                'From: ${task['start_date']} → ${task['end_date']}\nStatus: ${task['status']}'),
                          ),
                        );
                      },
                    ),
                  )
          ],
        ),
      ),
    );
  }
}
