import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config/api.dart';
import '../providers/auth_provider.dart';
import '../utilts/helpers.dart';

class SubmitComplaintScreen extends StatefulWidget {
  const SubmitComplaintScreen({super.key});

  @override
  State<SubmitComplaintScreen> createState() => _SubmitComplaintScreenState();
}

class _SubmitComplaintScreenState extends State<SubmitComplaintScreen> {
  String category = "Academic";
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  bool loading = false;

  Future<void> submit() async {
    setState(() => loading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/complaints"),
        headers: auth.authHeaders(),
        body: jsonEncode({
          "category": category,
          "title": titleCtrl.text.trim(),
          "description": descCtrl.text.trim(),
        }),
      );

      if (!mounted) return;

      if (res.statusCode == 201) {
        await showMsg(context, "Complaint submitted successfully");
        Navigator.pop(context);
      } else {
        final data = jsonDecode(res.body);
        await showMsg(context, data["message"] ?? "Submission failed");
      }
    } catch (e) {
      if (!mounted) return;
      await showMsg(context, "Error: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Submit Complaint")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: "Category"),
              items: const [
                DropdownMenuItem(value: "Academic", child: Text("Academic")),
                DropdownMenuItem(value: "Facility", child: Text("Facility")),
                DropdownMenuItem(value: "IT", child: Text("IT")),
                DropdownMenuItem(value: "Other", child: Text("Other")),
              ],
              onChanged: (v) => setState(() => category = v ?? "Academic"),
            ),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: descCtrl,
              maxLines: 5,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : submit,
                child: Text(loading ? "Submitting..." : "Submit"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
