import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api.dart';

class AuthProvider with ChangeNotifier {
  String _token = "";
  String _role = "";
  String _name = "";

  // ---------------- GETTERS ----------------
  String get token => _token;
  String get role => _role;
  String get name => _name;

  bool get isLoggedIn => _token.isNotEmpty;
  bool get isAdmin => _role == "admin";

  // ---------------- LOGIN ----------------
  Future<bool> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email.trim(),
          "password": password,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        _token = data["token"];
        _role = data["user"]["role"];
        _name = data["user"]["name"];

        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  // ---------------- LOGOUT ----------------
  void logout() {
    _token = "";
    _role = "";
    _name = "";
    notifyListeners();
  }

  // ---------------- AUTH HEADER ----------------
  Map<String, String> authHeaders() {
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $_token",
    };
  }
}
