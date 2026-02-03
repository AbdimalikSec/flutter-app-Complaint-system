import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config/api.dart';
import '../providers/auth_provider.dart';
import '../utilts/helpers.dart';
import 'complaint_details_screen.dart';

class AdminDepartmentsScreen extends StatefulWidget {
  const AdminDepartmentsScreen({super.key});

  @override
  State<AdminDepartmentsScreen> createState() => _AdminDepartmentsScreenState();
}

class _AdminDepartmentsScreenState extends State<AdminDepartmentsScreen> {
  bool loading = true;
  List complaints = [];

  Future<void> reload() async => loadComplaints();

  Future<void> loadComplaints() async {
    setState(() => loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/complaints"),
        headers: auth.authHeaders(),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        complaints = jsonDecode(res.body);
      } else {
        complaints = [];
        await showMsg(context, "Failed to load complaints");
      }
    } catch (e) {
      complaints = [];
      if (mounted) await showMsg(context, "Error: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _deptOf(Map c) {
    final student = c["studentId"];
    if (student is Map) {
      final d = (student["department"] ?? "").toString().trim();
      if (d.isNotEmpty) return d;
    }
    return "Unknown Department";
  }

  int _countStatus(List list, String status) =>
      list.where((c) => (c["status"] ?? "").toString() == status).length;

  @override
  void initState() {
    super.initState();
    loadComplaints();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    final Map<String, List> grouped = {};
    for (final c in complaints) {
      final dept = _deptOf(c as Map);
      grouped.putIfAbsent(dept, () => []);
      grouped[dept]!.add(c);
    }

    final depts = grouped.keys.toList()..sort();

    if (depts.isEmpty) {
      return const Center(child: Text("No complaints found"));
    }

    return RefreshIndicator(
      onRefresh: reload,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: depts.length,
        itemBuilder: (context, i) {
          final dept = depts[i];
          final list = grouped[dept]!;
          final pending = _countStatus(list, "Pending");
          final inProg = _countStatus(list, "In Progress");
          final resolved = _countStatus(list, "Resolved");

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dept,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Total complaints: ${list.length}",
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _StatusMini(
                        label: "Pending",
                        count: pending,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DepartmentComplaintsScreen(
                                department: dept,
                                complaints: list,
                                statusFilter: "Pending",
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      _StatusMini(
                        label: "Progress",
                        count: inProg,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DepartmentComplaintsScreen(
                                department: dept,
                                complaints: list,
                                statusFilter: "Progress",
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _StatusMini(
                        label: "Resolved",
                        count: resolved,
                        filled: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DepartmentComplaintsScreen(
                                department: dept,
                                complaints: list,
                                statusFilter: "Resolved",
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.list_alt_outlined),
                      label: const Text("View complaints"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DepartmentComplaintsScreen(
                              department: dept,
                              complaints: list,
                              statusFilter: "All",
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusMini extends StatelessWidget {
  final String label;
  final int count;
  final bool filled;
  final VoidCallback onTap;

  const _StatusMini({
    required this.label,
    required this.count,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Text("$label ($count)");

    return Expanded(
      child: filled
          ? ElevatedButton(onPressed: onTap, child: child)
          : OutlinedButton(onPressed: onTap, child: child),
    );
  }
}

class DepartmentComplaintsScreen extends StatelessWidget {
  final String department;
  final List complaints;
  final String statusFilter;

  const DepartmentComplaintsScreen({
    super.key,
    required this.department,
    required this.complaints,
    required this.statusFilter,
  });

  Color _statusColor(String status) {
    switch (status) {
      case "Resolved":
        return Colors.green.shade100;
      case "Progress":
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
  Widget build(BuildContext context) {
    final list = statusFilter == "All"
        ? complaints
        : complaints
              .where((c) => (c["status"] ?? "").toString() == statusFilter)
              .toList();

    return Scaffold(
      appBar: AppBar(title: Text("$department • $statusFilter")),
      body: list.isEmpty
          ? const Center(child: Text("No complaints"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final c = list[i] as Map;
                final title = (c["title"] ?? "").toString();
                final category = (c["category"] ?? "").toString();
                final status = (c["status"] ?? "").toString();
                final senderId = _senderId(c["studentId"]);

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.report_problem_outlined),
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      "Category: $category • Sender ID: $senderId",
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(status),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ComplaintDetailsScreen(complaint: c),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
