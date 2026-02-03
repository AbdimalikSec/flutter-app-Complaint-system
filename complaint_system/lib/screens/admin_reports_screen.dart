import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../config/api.dart';
import '../providers/auth_provider.dart';
import '../utilts/helpers.dart';
import 'complaint_details_screen.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  bool loading = true;
  List allComplaints = [];

  String statusFilter = "All";
  String departmentFilter = "All";

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
        allComplaints = jsonDecode(res.body);
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

  String _deptOf(Map c) {
    final student = c["studentId"];
    if (student is Map) {
      final d = (student["department"] ?? "").toString().trim();
      if (d.isNotEmpty) return d;
    }
    return "Unknown Department";
  }

  String _senderId(dynamic student) {
    if (student is Map) return (student["studentId"] ?? "-").toString();
    return "-";
  }

  List get filtered {
    return allComplaints.where((c) {
      final statusOk =
          statusFilter == "All" ||
          (c["status"] ?? "").toString() == statusFilter;
      final dept = _deptOf(c as Map);
      final deptOk = departmentFilter == "All" || dept == departmentFilter;
      return statusOk && deptOk;
    }).toList();
  }

  int _countStatus(List list, String status) {
    return list.where((c) => (c["status"] ?? "").toString() == status).length;
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

  String _csvEscape(String s) {
    final needsQuotes = s.contains(",") || s.contains("\n") || s.contains('"');
    if (!needsQuotes) return s;
    return '"${s.replaceAll('"', '""')}"';
  }

  String _buildCsv(List list) {
    final headers = [
      "createdAt",
      "status",
      "category",
      "title",
      "senderId",
      "department",
      "class",
      "description",
    ];

    final rows = <String>[];
    rows.add(headers.join(","));

    for (final item in list) {
      final c = item as Map;
      final student = c["studentId"];
      final createdAt = (c["createdAt"] ?? "").toString();
      final status = (c["status"] ?? "").toString();
      final category = (c["category"] ?? "").toString();
      final title = (c["title"] ?? "").toString();
      final desc = (c["description"] ?? "").toString();

      String sid = "-";
      String dept = "Unknown Department";
      String cls = "-";

      if (student is Map) {
        sid = (student["studentId"] ?? "-").toString();
        dept = (student["department"] ?? "Unknown Department").toString();
        cls = (student["classLevel"] ?? "-").toString();
      }

      final line = [
        _csvEscape(createdAt),
        _csvEscape(status),
        _csvEscape(category),
        _csvEscape(title),
        _csvEscape(sid),
        _csvEscape(dept),
        _csvEscape(cls),
        _csvEscape(desc),
      ].join(",");

      rows.add(line);
    }

    return rows.join("\n");
  }

  String _fileNameNow() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return "reports_${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}.csv";
  }

  Future<Directory?> _getDownloadsDirAndroid() async {
    // Best-effort Downloads path
    // This works on many devices, but not guaranteed. We'll fallback safely.
    final dir = Directory("/storage/emulated/0/Download");
    if (await dir.exists()) return dir;
    return null;
  }

  Future<void> exportCsvToFile() async {
    final list = filtered;
    final csv = _buildCsv(list);
    final fileName = _fileNameNow();

    try {
      // Try to get permission (older Android)
      final perm = await Permission.storage.request();

      Directory? targetDir;

      // Try Downloads on Android
      if (Platform.isAndroid) {
        targetDir = await _getDownloadsDirAndroid();
      }

      // Fallback to app documents directory
      targetDir ??= await getApplicationDocumentsDirectory();

      // If permission denied AND targetDir is downloads on old android, fallback
      if (!perm.isGranted && Platform.isAndroid) {
        targetDir = await getApplicationDocumentsDirectory();
      }

      final path = "${targetDir.path}/$fileName";
      final file = File(path);
      await file.writeAsString(csv, flush: true);

      if (!mounted) return;

      await showMsg(context, "Report saved: $path");
    } catch (e) {
      if (!mounted) return;
      await showMsg(context, "Export failed: $e");
    }
  }

  // keep old behavior available (optional)
  Future<void> exportCsvCopy() async {
    final list = filtered;
    final csv = _buildCsv(list);
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    await showMsg(context, "CSV copied (${list.length} rows)");
  }

  @override
  void initState() {
    super.initState();
    loadComplaints();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    final departments = <String>{};
    for (final c in allComplaints) {
      departments.add(_deptOf(c as Map));
    }

    final deptList = departments.toList()..sort();

    // ✅ ensure current value is valid
    if (departmentFilter != "All" && !deptList.contains(departmentFilter)) {
      departmentFilter = "All";
    }

    final list = filtered;
    final pending = _countStatus(list, "Pending");
    final inProg = _countStatus(list, "In Progress");
    final resolved = _countStatus(list, "Resolved");

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ clean header (no AppBar)
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Reports",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: exportCsvToFile,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text("Export"),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: reload,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: departmentFilter,
                      decoration: const InputDecoration(
                        labelText: "Department",
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: "All",
                          child: Text("All Departments"),
                        ),
                        ...deptList.map(
                          (d) => DropdownMenuItem(value: d, child: Text(d)),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => departmentFilter = v ?? "All"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: statusFilter,
                      decoration: const InputDecoration(labelText: "Status"),
                      items: const [
                        DropdownMenuItem(
                          value: "All",
                          child: Text("All Status"),
                        ),
                        DropdownMenuItem(
                          value: "Pending",
                          child: Text("Pending"),
                        ),
                        DropdownMenuItem(
                          value: "In Progress",
                          child: Text("In Progress"),
                        ),
                        DropdownMenuItem(
                          value: "Resolved",
                          child: Text("Resolved"),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => statusFilter = v ?? "All"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: null,
                      child: Text("Pending ($pending)"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: null,
                      child: Text("In Progress ($inProg)"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: null,
                      child: Text("Resolved ($resolved)"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text("Showing: ${list.length} complaints"),
              const SizedBox(height: 6),

              // Optional: small “Copy” action if you still want it
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: exportCsvCopy,
                  icon: const Icon(Icons.copy_all_outlined),
                  label: const Text("Copy CSV"),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: list.isEmpty
              ? const Center(child: Text("No complaints match filters"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final c = list[i] as Map;
                    final title = (c["title"] ?? "").toString();
                    final category = (c["category"] ?? "").toString();
                    final status = (c["status"] ?? "").toString();
                    final senderId = _senderId(c["studentId"]);
                    final dept = _deptOf(c);

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          "$dept • $category • Sender ID: $senderId",
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
                              builder: (_) =>
                                  ComplaintDetailsScreen(complaint: c),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
