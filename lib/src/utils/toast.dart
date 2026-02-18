import 'package:flutter/material.dart';

class Toast {
  static void show(String msg, BuildContext? context) {
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }
}
