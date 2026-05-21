import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme';

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  String get themeString {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'auto';
    }
  }

  ThemeProvider() {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_themeKey) ?? 'light';
      switch (saved) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'auto':
          _themeMode = ThemeMode.system;
          break;
      }
      notifyListeners();
    } catch (e) {
      print('Error loading theme: $e');
    }
  }

  Future<void> changeTheme(String themeString) async {
    ThemeMode newMode;
    switch (themeString) {
      case 'light':
        newMode = ThemeMode.light;
        break;
      case 'dark':
        newMode = ThemeMode.dark;
        break;
      case 'auto':
        newMode = ThemeMode.system;
        break;
      default:
        newMode = ThemeMode.light;
    }

    if (_themeMode == newMode) return;

    try {
      _themeMode = newMode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, themeString);
      notifyListeners();
    } catch (e) {
      print('Error changing theme: $e');
    }
  }
}