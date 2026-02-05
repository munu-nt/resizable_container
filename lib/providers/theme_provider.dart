import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  Color _seedColor = Colors.deepPurple;
  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  ThemeData get lightTheme => ThemeData.light().copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.grey.shade100,
  );
  ThemeData get darkTheme => ThemeData.dark().copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
  );
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  void setSeedColor(Color color) {
    _seedColor = color;
    notifyListeners();
  }

  void resetTheme() {
    _themeMode = ThemeMode.light;
    _seedColor = Colors.deepPurple;
    notifyListeners();
  }
}
