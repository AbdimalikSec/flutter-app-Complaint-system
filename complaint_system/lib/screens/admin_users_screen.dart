import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config/api.dart';
import '../providers/auth_provider.dart';
import '../utilts/helpers.dart';
import 'create_student_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool loading = true;
  List users = [];

  Future<void> reload() async => loadUsers();

  Future<void> loadUsers({bool silent = false}) async {
    if (!silent) setState(() => loading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/admin/users"),
        headers: auth.authHeaders(),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        users = jsonDecode(res.body);
      } else {
        users = [];
        await showMsg(context, "Failed to load students");
      }
    } catch (e) {
      users = [];
      if (mounted) await showMsg(context, "Error: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> toggleActive(String userId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final res = await http.put(
        Uri.parse("$baseUrl/api/admin/users/$userId/toggle"),
        headers: auth.authHeaders(),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        await loadUsers(silent: true);
      } else {
        await showMsg(context, "Failed to update status");
      }
    } catch (e) {
      if (mounted) await showMsg(context, "Error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ No Scaffold / no AppBar (because AdminDashboard already has one)

    if (loading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "Manage Students",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(icon: const Icon(Icons.refresh), onPressed: reload),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Create"),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateStudentScreen(),
                    ),
                  );
                  loadUsers(silent: true);
                },
              ),
            ],
          ),
        ),

        Expanded(
          child: users.isEmpty
              ? RefreshIndicator(
                  onRefresh: () => loadUsers(silent: true),
                  child: ListView(
                    children: const [
                      SizedBox(height: 200),
                      Center(child: Text("No students found")),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => loadUsers(silent: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: users.length,
                    itemBuilder: (context, i) {
                      final u = users[i];

                      final isActive = u["isActive"] == true;
                      final dept = (u["department"] ?? "").toString();
                      final cls = (u["classLevel"] ?? "").toString();

                      final subtitleStr =
                          "ID: ${(u["studentId"] ?? "").toString()}\n"
                          "${dept.isEmpty ? "" : dept} ${dept.isNotEmpty && cls.isNotEmpty ? "•" : ""} ${cls.isEmpty ? "" : cls}";

                      return Card(
                        child: ListTile(
                          title: Text((u["name"] ?? "").toString()),
                          subtitle: Text(subtitleStr.trim()),
                          isThreeLine: true,
                          trailing: Switch(
                            value: isActive,
                            onChanged: (_) => toggleActive(u["_id"].toString()),
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
}
