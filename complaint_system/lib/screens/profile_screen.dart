import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    final name = auth.name ?? "User";
    final role = auth.role;
    final sid = auth.studentId ?? "-";
    final dept = (auth.department ?? "").trim();
    final cls = (auth.classLevel ?? "").trim();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const CircleAvatar(radius: 36, child: Icon(Icons.person, size: 40)),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text("Role: $role"),
          const SizedBox(height: 18),

          Card(
            child: ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: Text("Student ID: $sid"),
              subtitle: Text(
                "${dept.isEmpty ? "Department: -" : "Department: $dept"}\n"
                "${cls.isEmpty ? "Class: -" : "Class: $cls"}",
              ),
              isThreeLine: true,
            ),
          ),

          const Card(
            child: ListTile(
              leading: Icon(Icons.security),
              title: Text("Account"),
              subtitle: Text("Provider state + JWT auth"),
            ),
          ),
        ],
      ),
    );
  }
}
