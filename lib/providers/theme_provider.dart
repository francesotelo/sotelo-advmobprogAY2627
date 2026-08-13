import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFFFC0CB), 
        scaffoldBackgroundColor: const Color(0xFFF3E5F5), 
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFC0CB),
          foregroundColor: Colors.black87,
          elevation: 2,
        ),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFFC0CB),
          secondary: Color(0xFFFFF59D), 
          surface: Colors.white,
        ),
        cardColor: Colors.white,
      );

  ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF8E24AA),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF8E24AA),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8E24AA),
          secondary: Color(0xFFFF4081),
          surface: Color(0xFF1E1E1E),
        ),
        cardColor: const Color(0xFF1E1E1E),
      );

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}