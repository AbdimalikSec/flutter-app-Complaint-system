import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config/api.dart';
import '../providers/auth_provider.dart';
import '../utilts/helpers.dart';

class MyComplaintsTab extends StatefulWidget {
  const MyComplaintsTab({super.key});

  @override
  State<MyComplaintsTab> createState() => _MyComplaintsTabState();
}

class _MyComplaintsTabState extends State<MyComplaintsTab> {
  bool loading = true;
  List complaints = [];

  Future<void> loadComplaints() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/complaints/mine"),
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

  void showTimeline(BuildContext context, List history, String currentStatus) {
    final safeHistory = history.isEmpty
        ? [
            {"status": currentStatus, "date": DateTime.now().toIso8601String()},
          ]
        : history;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Complaint Timeline",
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
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    loadComplaints();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    if (complaints.isEmpty) {
      return const Center(child: Text("No complaints found"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: complaints.length,
      itemBuilder: (context, i) {
        final c = complaints[i];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.report_problem_outlined),
            title: Text(c["title"] ?? ""),
            subtitle: Text("${c["category"]} • Status: ${c["status"]}"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                showTimeline(context, c["statusHistory"] ?? [], c["status"]),
          ),
        );
      },
    );
  }
}
