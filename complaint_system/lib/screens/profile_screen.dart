import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const CircleAvatar(radius: 36, child: Icon(Icons.person, size: 40)),
          const SizedBox(height: 12),
          Text(auth.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text("Role: ${auth.role}"),
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              leading: const Icon(Icons.security),
              title: const Text("Account"),
              subtitle: const Text("Provider state + JWT auth"),
            ),
          )
        ],
      ),
    );
  }
}
