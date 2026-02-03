import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart'; // adjust path if different

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false, // ✅ removes the red DEBUG banner
        title: 'Complaint System',
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
      ),
    );
  }
}
