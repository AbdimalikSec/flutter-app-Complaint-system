import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config/api.dart';
import '../providers/auth_provider.dart';
import '../utilts/helpers.dart';
import 'submit_complaint_screen.dart';

class StudentHomeTab extends StatefulWidget {
  const StudentHomeTab({super.key});

  @override
  State<StudentHomeTab> createState() => _StudentHomeTabState();
}

class _StudentHomeTabState extends State<StudentHomeTab> {
  bool loadingCount = true;
  int complaintCount = 0;

  Future<void> loadCount() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/complaints/mine"),
        headers: auth.authHeaders(),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body);
        complaintCount = (list as List).length;
      } else {
        complaintCount = 0;
      }
    } catch (e) {
      complaintCount = 0;
      if (mounted) {
        await showMsg(context, "Error loading dashboard: $e");
      }
    } finally {
      if (mounted) setState(() => loadingCount = false);
    }
  }

  @override
  void initState() {
    super.initState();
    loadCount();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    final name = auth.name ?? "Student";
    final sid = auth.studentId ?? "-";
    final dept = (auth.department ?? "").trim();
    final cls = (auth.classLevel ?? "").trim();

    final deptLine = dept.isEmpty ? "Department: -" : "Department: $dept";
    final classLine = cls.isEmpty ? "Class: -" : "Class: $cls";

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 34,
            child: Icon(Icons.person, size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            "Welcome, $name!",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            "Submit a complaint and track status easily.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),

          Card(
            child: ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: Text("Student ID: $sid"),
              subtitle: Text("$deptLine\n$classLine"),
              isThreeLine: true,
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text("My Complaints"),
              subtitle: Text(
                loadingCount ? "Loading..." : "Total submitted: $complaintCount",
              ),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() => loadingCount = true);
                  loadCount();
                },
              ),
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text("Submit Complaint"),
              subtitle: const Text("Create a new complaint"),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubmitComplaintScreen()),
                );
                // refresh count when back
                setState(() => loadingCount = true);
                loadCount();
              },
            ),
          ),

          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text("Tip"),
              subtitle: Text("Use the bottom tabs to view complaints and profile."),
            ),
          ),
        ],
      ),
    );
  }
}
