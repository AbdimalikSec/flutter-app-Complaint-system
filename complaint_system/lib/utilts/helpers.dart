import 'package:flutter/material.dart';

Future<void> showMsg(BuildContext context, String msg) async {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg)),
  );
}
