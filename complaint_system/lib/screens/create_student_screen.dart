import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config/api.dart';
import '../providers/auth_provider.dart';
import '../utilts/helpers.dart';

class CreateStudentScreen extends StatefulWidget {
  const CreateStudentScreen({super.key});

  @override
  State<CreateStudentScreen> createState() => _CreateStudentScreenState();
}

class _CreateStudentScreenState extends State<CreateStudentScreen> {
  final idCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool loading = false;

  final List<String> departments = const [
    "Computer Science",
    "Business",
    "Engineering",
    "Medicine",
  ];

  final Map<String, List<String>> classesByDept = const {
    "Computer Science": [
      "CS101 - Intro Programming",
      "CS205 - Data Structures",
      "CS310 - Mobile Development",
    ],
    "Business": [
      "BUS101 - Principles of Business",
      "BUS210 - Marketing",
      "BUS330 - Entrepreneurship",
    ],
    "Engineering": [
      "ENGR101 - Engineering Basics",
      "ENGR220 - Circuits",
      "ENGR340 - Mechanics",
    ],
    "Medicine": [
      "MED101 - Human Anatomy",
      "MED210 - Physiology",
      "MED330 - Clinical Practice",
    ],
  };

  String? selectedDepartment;
  String? selectedClass;

  // --- frontend validation helpers ---
  bool _validStudentId(String s) {
    final v = s.trim();
    return RegExp(r'^[A-Za-z0-9_-]{4,20}$').hasMatch(v);
  }

  bool _validName(String name) {
    final n = name.trim();
    if (n.length < 2 || n.length > 60) return false;
    if (!RegExp(r'[A-Za-z]').hasMatch(n)) return false; // must contain letters
    return RegExp(r"^[A-Za-z][A-Za-z\s.'-]*$").hasMatch(n);
  }

  Future<void> create() async {
    final sid = idCtrl.text.trim();
    final fullName = nameCtrl.text.trim();
    final password = passCtrl.text;

    if (sid.isEmpty || fullName.isEmpty || password.isEmpty) {
      await showMsg(context, "Student ID, Name and Password are required");
      return;
    }

    if (!_validStudentId(sid)) {
      await showMsg(
        context,
        "Invalid Student ID (use 4-20 chars: letters/numbers/_/-)",
      );
      return;
    }

    if (!_validName(fullName)) {
      await showMsg(
        context,
        "Invalid Name (must contain letters, not only numbers)",
      );
      return;
    }

    if (password.length < 6) {
      await showMsg(context, "Password must be at least 6 characters");
      return;
    }

    if (selectedDepartment == null) {
      await showMsg(context, "Please select a department");
      return;
    }

    if (selectedClass == null) {
      await showMsg(context, "Please select a class");
      return;
    }

    setState(() => loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/admin/users"),
        headers: auth.authHeaders(),
        body: jsonEncode({
          "studentId": sid,
          "name": fullName,
          "department": selectedDepartment,
          "classLevel": selectedClass,
          "password": password,
        }),
      );

      if (!mounted) return;

      if (res.statusCode == 201) {
        await showMsg(context, "Student created");
        Navigator.pop(context);
      } else {
        final data = jsonDecode(res.body);
        await showMsg(context, data["message"]?.toString() ?? "Failed");
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
    idCtrl.dispose();
    nameCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classOptions = selectedDepartment == null
        ? <String>[]
        : (classesByDept[selectedDepartment] ?? []);

    return Scaffold(
      appBar: AppBar(title: const Text("Create Student")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: idCtrl,
              decoration: const InputDecoration(
                labelText: "Student ID",
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: "Full Name",
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: selectedDepartment,
              decoration: const InputDecoration(
                labelText: "Department",
                prefixIcon: Icon(Icons.apartment_outlined),
              ),
              items: departments
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  selectedDepartment = v;
                  selectedClass = null;
                });
              },
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: selectedClass,
              decoration: const InputDecoration(
                labelText: "Class",
                prefixIcon: Icon(Icons.class_outlined),
              ),
              items: classOptions
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => selectedClass = v),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),

            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : create,
                child: Text(loading ? "Please wait..." : "Create Student"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
