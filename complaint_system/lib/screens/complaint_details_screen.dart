import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config/api.dart';
import '../providers/auth_provider.dart';
import '../utilts/helpers.dart';

class ComplaintDetailsScreen extends StatefulWidget {
  final Map complaint;

  const ComplaintDetailsScreen({super.key, required this.complaint});

  @override
  State<ComplaintDetailsScreen> createState() => _ComplaintDetailsScreenState();
}

class _ComplaintDetailsScreenState extends State<ComplaintDetailsScreen> {
  late Map complaint;
  bool updating = false;

  @override
  void initState() {
    super.initState();
    complaint = widget.complaint;
  }

  String _studentLine(dynamic student) {
    if (student == null || student is! Map) return "Unknown sender";

    final n = (student["name"] ?? "").toString().trim();
    final sid = (student["studentId"] ?? "").toString().trim();
    final dept = (student["department"] ?? "").toString().trim();
    final cls = (student["classLevel"] ?? "").toString().trim();

    final parts = <String>[];
    if (sid.isNotEmpty) parts.add("ID: $sid");
    if (dept.isNotEmpty) parts.add(dept);
    if (cls.isNotEmpty) parts.add(cls);

    final who = n.isNotEmpty ? n : "Student";
    return parts.isEmpty ? who : "$who • ${parts.join(" • ")}";
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

  void showTimeline(BuildContext context, List history, String currentStatus) {
    final safeHistory = history.isEmpty
        ? [
            {"status": currentStatus, "date": DateTime.now().toIso8601String()}
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
                title: Text(h["status"].toString()),
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

  Future<void> updateStatus(String status) async {
    setState(() => updating = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final res = await http.put(
        Uri.parse("$baseUrl/api/complaints/${complaint["_id"]}/status"),
        headers: auth.authHeaders(),
        body: jsonEncode({"status": status}),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        complaint = jsonDecode(res.body);
        setState(() {});
        await showMsg(context, "Status updated");
      } else {
        await showMsg(context, "Failed to update status");
      }
    } catch (e) {
      if (!mounted) return;
      await showMsg(context, "Error: $e");
    } finally {
      if (mounted) setState(() => updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (complaint["status"] ?? "").toString();
    final category = (complaint["category"] ?? "").toString();
    final title = (complaint["title"] ?? "").toString();
    final desc = (complaint["description"] ?? "").toString();
    final student = complaint["studentId"];
    final history = (complaint["statusHistory"] ?? []) as List;

    DateTime? createdAt;
    try {
      createdAt = DateTime.parse((complaint["createdAt"] ?? "").toString());
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(
        title: const Text("Complaint Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(status),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text("Category: $category"),
            const SizedBox(height: 6),

            Text("Sender: ${_studentLine(student)}"),
            if (createdAt != null) ...[
              const SizedBox(height: 6),
              Text(
                "Created: ${createdAt.day}/${createdAt.month}/${createdAt.year} "
                "${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}",
              ),
            ],

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  desc,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
              ),
            ),

            const SizedBox(height: 10),

            TextButton.icon(
              icon: const Icon(Icons.timeline),
              label: const Text("View Timeline"),
              onPressed: () => showTimeline(context, history, status),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: updating ? null : () => updateStatus("In Progress"),
                    child: Text(updating ? "Please wait..." : "In Progress"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: updating ? null : () => updateStatus("Resolved"),
                    child: Text(updating ? "Please wait..." : "Resolved"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
