import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config/api.dart';
import '../providers/auth_provider.dart';
import '../utilts/helpers.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool loading = true;
  List allComplaints = [];
  List filteredComplaints = [];

  String searchText = "";
  String statusFilter = "All";
  String categoryFilter = "All";

  final searchCtrl = TextEditingController();

  // ================= LOAD =================
  Future<void> loadComplaints() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/complaints"),
        headers: auth.authHeaders(),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        allComplaints = jsonDecode(res.body);
        applyFilters();
      } else {
        allComplaints = [];
        await showMsg(context, "Failed to load complaints");
      }
    } catch (e) {
      allComplaints = [];
      if (mounted) await showMsg(context, "Error: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ================= FILTER LOGIC =================
  void applyFilters() {
    filteredComplaints = allComplaints.where((c) {
      final matchesSearch = c["title"]
          .toString()
          .toLowerCase()
          .contains(searchText.toLowerCase());

      final matchesStatus =
          statusFilter == "All" || c["status"] == statusFilter;

      final matchesCategory =
          categoryFilter == "All" || c["category"] == categoryFilter;

      return matchesSearch && matchesStatus && matchesCategory;
    }).toList();

    setState(() {});
  }

  // ================= UPDATE STATUS =================
  Future<void> updateStatus(String id, String status) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    await http.put(
      Uri.parse("$baseUrl/api/complaints/$id/status"),
      headers: auth.authHeaders(),
      body: jsonEncode({ "status": status }),
    );

    loadComplaints();
  }

  // ================= TIMELINE =================
  void showTimeline(BuildContext context, List history, String currentStatus) {
    final safeHistory = history.isEmpty
        ? [
            {
              "status": currentStatus,
              "date": DateTime.now().toIso8601String(),
            }
          ]
        : history;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Complaint Status Timeline",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...safeHistory.map((h) {
              final date = DateTime.parse(h["date"]);
              return ListTile(
                leading: const Icon(Icons.timeline),
                title: Text(h["status"]),
                subtitle: Text(
                  "${date.day}/${date.month}/${date.year} "
                  "${date.hour}:${date.minute.toString().padLeft(2, '0')}",
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
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
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🔍 FILTER BAR
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

                // 📋 COMPLAINT LIST
                Expanded(
                  child: filteredComplaints.isEmpty
                      ? const Center(child: Text("No complaints match filters"))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredComplaints.length,
                          itemBuilder: (context, i) {
                            final c = filteredComplaints[i];

                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            c["title"],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _statusColor(c["status"]),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(c["status"]),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text("Category: ${c["category"]}"),
                                    const SizedBox(height: 8),
                                    Text(c["description"]),
                                    TextButton.icon(
                                      icon: const Icon(Icons.timeline),
                                      label: const Text("View Timeline"),
                                      onPressed: () => showTimeline(
                                        context,
                                        c["statusHistory"] ?? [],
                                        c["status"],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        OutlinedButton(
                                          onPressed: () => updateStatus(
                                            c["_id"],
                                            "In Progress",
                                          ),
                                          child: const Text("In Progress"),
                                        ),
                                        const SizedBox(width: 10),
                                        ElevatedButton(
                                          onPressed: () => updateStatus(
                                            c["_id"],
                                            "Resolved",
                                          ),
                                          child: const Text("Resolved"),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
