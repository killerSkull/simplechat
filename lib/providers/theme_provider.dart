import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/themes.dart';

enum AppTheme { 
  light, 
  dark, 
  pixel, 
  midnightBlue, 
  classicTerminal, 
  whatsAppNocturno, 
  brisaPastel 
}

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData = pixelTheme; // Tema por defecto
  AppTheme _currentTheme = AppTheme.pixel;
  bool _isLoading = true;

  ThemeData get themeData => _themeData;
  AppTheme get currentTheme => _currentTheme;
  bool get isLoading => _isLoading;

  final Map<AppTheme, String> themeNames = {
    AppTheme.light: 'Claro',
    AppTheme.dark: 'Oscuro',
    AppTheme.pixel: 'Píxel',
    AppTheme.midnightBlue: 'Medianoche',
    AppTheme.classicTerminal: 'Terminal',
    AppTheme.whatsAppNocturno: 'Nocturno',
    AppTheme.brisaPastel: 'Pastel',
  };

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme') ?? AppTheme.pixel.index;
    _currentTheme = AppTheme.values[themeIndex];
    _themeData = _getThemeData(_currentTheme);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    _themeData = _getThemeData(theme);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme', theme.index);
  }

  ThemeData _getThemeData(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return lightTheme;
      case AppTheme.dark:
        return darkTheme;
      case AppTheme.pixel:
        return pixelTheme;
      case AppTheme.midnightBlue:
        // Este tema no estaba definido, lo asignamos a uno existente
        // o puedes crearlo en themes.dart
        return darkTheme; 
      case AppTheme.classicTerminal:
        return classicTerminalTheme;
      case AppTheme.whatsAppNocturno:
        return whatsAppNocturnoTheme;
      case AppTheme.brisaPastel:
        return brisaPastelTheme;
    }
  }
}