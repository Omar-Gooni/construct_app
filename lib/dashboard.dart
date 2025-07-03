import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

import 'login.dart';
import 'projects.dart';
import 'workers.dart';
import 'material_inventory.dart';
import 'tasks.dart';
import 'user_management.dart';
import 'reports.dart';

class DashboardPage extends StatefulWidget {
  final String role;
  final String userId;

  const DashboardPage({
    super.key,
    required this.role,
    required this.userId,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  Timer? _timer;

  Map<String, dynamic> stats = {
    'projects': 0,
    'workers': 0,
    'materials': 0,
    'tasks': 0,
    'pending': 0,
    'in_progress': 0,
    'completed': 0,
  };

  List<Map<String, dynamic>> lowStockMaterials = [];

  @override
  void initState() {
    super.initState();
    fetchStats();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchStats());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchStats() async {
    final res = await http.get(Uri.parse('http://172.20.10.4/flutter_api/get_stats.php'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['success']) {
        final rawStats = data['stats'];
        setState(() {
          stats = {
            'projects': int.parse(rawStats['projects'].toString()),
            'workers': int.parse(rawStats['workers'].toString()),
            'materials': int.parse(rawStats['materials'].toString()),
            'tasks': int.parse(rawStats['tasks'].toString()),
            'pending': int.parse(rawStats['pending'].toString()),
            'in_progress': int.parse(rawStats['in_progress'].toString()),
            'completed': int.parse(rawStats['completed'].toString()),
          };
        });
      }
    }

    if (widget.role == 'admin') {
      final lowRes = await http.get(Uri.parse('http://172.20.10.4/flutter_api/get_low_materials.php'));
      if (lowRes.statusCode == 200) {
        final lowData = jsonDecode(lowRes.body);
        if (lowData['success']) {
          setState(() {
            lowStockMaterials = List<Map<String, dynamic>>.from(lowData['materials']);
          });
        }
      }
    }
  }

  Widget buildDashboard() {
    return RefreshIndicator(
      onRefresh: fetchStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to CIGAL CONSTRUCT',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(child: dashboardCard('Projects', stats['projects'], 1, Icons.business)),
                const SizedBox(width: 12),
                Expanded(child: dashboardCard('Workers', stats['workers'], 2, Icons.people)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: dashboardCard('Materials', stats['materials'], 3, Icons.inventory)),
                const SizedBox(width: 12),
                Expanded(child: dashboardCard('Tasks', stats['tasks'], 4, Icons.task)),
              ],
            ),

            const SizedBox(height: 24),
            const Text(
              'Task Status Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: TaskPieChart(
                pending: stats['pending'],
                inProgress: stats['in_progress'],
                completed: stats['completed'],
              ),
            ),

            if (widget.role == 'admin' && lowStockMaterials.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Low Stock Alerts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Column(
                children: lowStockMaterials.map((material) {
                  int quantity = int.parse(material['quantity'].toString());
                  Color alertColor = quantity < 5 ? Colors.red.shade100 : Colors.blue.shade100;
                  return Card(
                    color: alertColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      title: Text(material['material_name']),
                      subtitle: Text("Quantity waaa uu yaryahy waxa uuna maryaa: $quantity"),
                      trailing: Icon(Icons.warning, color: quantity < 5 ? Colors.red : Colors.blue),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget dashboardCard(String title, int value, int navIndex, IconData icon) {
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = navIndex),
      child: Card(
        color: Colors.orange.shade50,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.deepOrange, size: 28),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value.toString(), style: const TextStyle(fontSize: 20, color: Colors.blue)),
            ],
          ),
        ),
      ),
    );
  }

  static const List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
    BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Projects'),
    BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Workers'),
    BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Inventory'),
    BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),
    BottomNavigationBarItem(icon: Icon(Icons.people_alt), label: 'Users'),
    BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Reports'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      buildDashboard(),
      ProjectsPage(role: widget.role),
      WorkersPage(role: widget.role),
      MaterialInventoryPage(role: widget.role),
      TasksPage(role: widget.role),
      UserManagementPage(role: widget.role),
      ReportsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('CIGAL CONSTRUCT'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Text(
                widget.role.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context)),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class TaskPieChart extends StatelessWidget {
  final int pending;
  final int inProgress;
  final int completed;

  const TaskPieChart({
    super.key,
    required this.pending,
    required this.inProgress,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final total = pending + inProgress + completed;
    if (total == 0) {
      return const Center(child: Text("No task data to display"));
    }

    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(value: pending.toDouble(), color: Colors.orange, title: 'Pending'),
          PieChartSectionData(value: inProgress.toDouble(), color: Colors.blue, title: 'In Progress'),
          PieChartSectionData(value: completed.toDouble(), color: Colors.green, title: 'Completed'),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }
}
