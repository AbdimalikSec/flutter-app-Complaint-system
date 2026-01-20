import 'package:flutter/material.dart';
import 'submit_complaint_screen.dart';

class StudentHomeTab extends StatelessWidget {
  const StudentHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 34,
            child: Icon(Icons.person, size: 36),
          ),
          const SizedBox(height: 14),
          const Text(
            "Welcome!",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            "Submit a complaint and track status easily.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),

          Card(
            child: ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text("Submit Complaint"),
              subtitle: const Text("Create a new complaint"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubmitComplaintScreen()),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

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
