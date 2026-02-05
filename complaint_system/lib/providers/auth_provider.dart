import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String _role = "student";

  String? studentId;
  String? email;
  String? name;
  String? department;
  String? classLevel;
  bool isActive = true;

  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  bool get isAdmin => _role == "admin";
  String get role => _role;

  String? get token => _token;

  // Used by every authenticated request
  Map<String, String> authHeaders() {
    return {
      "Content-Type": "application/json",
      if (_token != null) "Authorization": "Bearer $_token",
    };
  }

  /// Login using a single identifier input:
  /// - student enters studentId
  /// - admin enters email
  Future<bool> login(String input, String password) async {
    try {
      final res = await http
          .post(
            Uri.parse("$baseUrl/api/auth/login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "identifier": input.trim(), // studentId OR email
              "password": password,
            }),
          )
          .timeout(apiTimeout);

      if (res.statusCode != 200) return false;

      final data = jsonDecode(res.body);
      _token = data["token"]?.toString();
      _role = (data["user"]["role"] ?? "student").toString();

      name = data["user"]["name"]?.toString();
      studentId = data["user"]["studentId"]?.toString();
      email = data["user"]["email"]?.toString();
      department = data["user"]["department"]?.toString();
      classLevel = data["user"]["classLevel"]?.toString();
      isActive = data["user"]["isActive"] == true;

      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void logout() {
    _token = null;
    _role = "student";

    studentId = null;
    email = null;
    name = null;
    department = null;
    classLevel = null;
    isActive = true;

    notifyListeners();
  }
}
