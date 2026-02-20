import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Colors.orange;

  static ThemeData light() => ThemeData(
        primarySwatch: primary,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.black,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
        ),
      );
}
