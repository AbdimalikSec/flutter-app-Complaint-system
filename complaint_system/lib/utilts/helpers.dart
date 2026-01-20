import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

Future<Map<String, String>> authHeaders(BuildContext context) async {
  final auth = Provider.of<AuthProvider>(context, listen: false);
  return auth.authHeaders();
}

Future<void> showMsg(BuildContext context, String msg) async {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg)),
  );
}
