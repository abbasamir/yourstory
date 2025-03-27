import 'package:flutter/material.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light; // Default theme mode is light

  ThemeMode get themeMode => _themeMode;

  // Set the theme mode directly
  void setThemeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    notifyListeners();
  }

  // Define the light theme
  ThemeData get lightTheme => ThemeData(
    primaryColor: Colors.purple,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    ),
  );

  // Define the dark theme
  ThemeData get darkTheme => ThemeData(
    primaryColor: Colors.deepPurple,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
  );

  // Get the current theme based on the current theme mode
  ThemeData get currentTheme => _themeMode == ThemeMode.dark ? darkTheme : lightTheme;
}
