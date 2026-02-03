import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utilts/helpers.dart';
import 'admin_dashboard_screen.dart';
import 'student_main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final studentIdCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool loading = false;

  Future<void> login() async {
    if (studentIdCtrl.text.trim().isEmpty || passCtrl.text.isEmpty) {
      await showMsg(context, "Please enter Student ID and password");
      return;
    }

    setState(() => loading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await auth.login(
      studentIdCtrl.text.trim(),
      passCtrl.text,
    );

    if (!mounted) return;

    if (ok) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              auth.isAdmin ? const AdminDashboardScreen() : const StudentMainScreen(),
        ),
      );
    } else {
      await showMsg(
        context,
        "Login failed. Student ID or password is incorrect.",
      );
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  void dispose() {
    studentIdCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 40,
                  child: Icon(Icons.lock, size: 40),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Campus Complaint System",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text("Login to continue"),
                const SizedBox(height: 20),

                TextField(
                  controller: studentIdCtrl,
                  decoration: const InputDecoration(
                    labelText: "Student ID",
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: loading ? null : login,
                    child: Text(
                      loading ? "Please wait..." : "Login",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
