import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config/api.dart';
import '../providers/auth_provider.dart';
import '../utilts/helpers.dart';
import 'login_screen.dart';
import 'admin_users_screen.dart';
import 'admin_departments_screen.dart';
import 'admin_reports_screen.dart';
import 'complaint_details_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentTab = 0;

  // ---------- Complaints tab state ----------
  bool loading = true;
  List allComplaints = [];
  List filteredComplaints = [];

  String searchText = "";
  String statusFilter = "All";
  String categoryFilter = "All";

  final searchCtrl = TextEditingController();

  // ---------- Load complaints ----------
  Future<void> loadComplaints({bool silent = false}) async {
    if (!silent) setState(() => loading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/complaints"),
        headers: auth.authHeaders(),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        allComplaints = jsonDecode(res.body);
        applyFilters(silent: true);
      } else {
        allComplaints = [];
        filteredComplaints = [];
        await showMsg(context, "Failed to load complaints");
      }
    } catch (e) {
      allComplaints = [];
      filteredComplaints = [];
      if (mounted) await showMsg(context, "Error: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void applyFilters({bool silent = false}) {
    filteredComplaints = allComplaints.where((c) {
      final matchesSearch = (c["title"] ?? "")
          .toString()
          .toLowerCase()
          .contains(searchText.toLowerCase());

      final matchesStatus = statusFilter == "All" || c["status"] == statusFilter;
      final matchesCategory = categoryFilter == "All" || c["category"] == categoryFilter;

      return matchesSearch && matchesStatus && matchesCategory;
    }).toList();

    if (!silent) setState(() {});
  }

  Color _statusColor(String status) {
    switch (status) {
      case "Resolved":
        return Colors.green.shade100;
      case "In Progress":
        return Colors.orange.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  String _senderId(dynamic student) {
    if (student is Map) return (student["studentId"] ?? "-").toString();
    return "-";
  }

  @override
  void initState() {
    super.initState();
    loadComplaints();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  String _titleForTab(int i) {
    switch (i) {
      case 0:
        return "Admin Dashboard";
      case 1:
        return "Departments";
      case 2:
        return "Reports";
      case 3:
        return "Students";
      default:
        return "Admin";
    }
  }

  Widget _buildComplaintsTab() {
    if (loading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: searchCtrl,
                decoration: const InputDecoration(
                  labelText: "Search by title",
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) {
                  searchText = v;
                  applyFilters();
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: statusFilter,
                      items: const [
                        DropdownMenuItem(value: "All", child: Text("All Status")),
                        DropdownMenuItem(value: "Pending", child: Text("Pending")),
                        DropdownMenuItem(value: "In Progress", child: Text("In Progress")),
                        DropdownMenuItem(value: "Resolved", child: Text("Resolved")),
                      ],
                      onChanged: (v) {
                        statusFilter = v!;
                        applyFilters();
                      },
                      decoration: const InputDecoration(labelText: "Status"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: categoryFilter,
                      items: const [
                        DropdownMenuItem(value: "All", child: Text("All Categories")),
                        DropdownMenuItem(value: "Academic", child: Text("Academic")),
                        DropdownMenuItem(value: "Facility", child: Text("Facility")),
                        DropdownMenuItem(value: "IT", child: Text("IT")),
                        DropdownMenuItem(value: "Other", child: Text("Other")),
                      ],
                      onChanged: (v) {
                        categoryFilter = v!;
                        applyFilters();
                      },
                      decoration: const InputDecoration(labelText: "Category"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredComplaints.isEmpty
              ? const Center(child: Text("No complaints match filters"))
              : RefreshIndicator(
                  onRefresh: () => loadComplaints(silent: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredComplaints.length,
                    itemBuilder: (context, i) {
                      final c = filteredComplaints[i];
                      final student = c["studentId"];

                      final title = (c["title"] ?? "").toString();
                      final category = (c["category"] ?? "").toString();
                      final status = (c["status"] ?? "").toString();
                      final senderId = _senderId(student);

                      return Card(
                        child: ListTile(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ComplaintDetailsScreen(complaint: c as Map),
                              ),
                            );
                            loadComplaints(silent: true);
                          },
                          leading: const Icon(Icons.report_problem_outlined),
                          title: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text("Category: $category • Sender ID: $senderId"),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(status),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(status),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final pages = <Widget>[
      _buildComplaintsTab(),
      const AdminDepartmentsScreen(),
      const AdminReportsScreen(),
      const AdminUsersScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForTab(_currentTab)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: pages[_currentTab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), label: "Complaints"),
          BottomNavigationBarItem(icon: Icon(Icons.apartment_outlined), label: "Departments"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: "Reports"),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), label: "Students"),
        ],
      ),
    );
  }
}
