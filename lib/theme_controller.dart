import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  AppThemeMode _appTheme = AppThemeMode.system;

  ThemeProvider() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;
  AppThemeMode get appTheme => _appTheme;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode') ?? 'system';
    switch (saved) {
      case 'light':
        _themeMode = ThemeMode.light;
        _appTheme = AppThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        _appTheme = AppThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
        _appTheme = AppThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setTheme(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    _appTheme = mode;

    switch (mode) {
      case AppThemeMode.light:
        _themeMode = ThemeMode.light;
        await prefs.setString('theme_mode', 'light');
        break;
      case AppThemeMode.dark:
        _themeMode = ThemeMode.dark;
        await prefs.setString('theme_mode', 'dark');
        break;
      case AppThemeMode.system:
        _themeMode = ThemeMode.system;
        await prefs.setString('theme_mode', 'system');
        break;
    }
    notifyListeners();
  }
}
