import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/themes.dart';

// --- MODIFICADO: Se añade el nuevo tema al enum ---
enum AppTheme { light, dark, pixel, midnightBlue }

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData = pixelTheme;
  AppTheme _currentTheme = AppTheme.pixel;

  ThemeData get themeData => _themeData;
  AppTheme get currentTheme => _currentTheme;

  // --- NUEVO: Mapa para mostrar nombres amigables en la UI ---
  final Map<AppTheme, String> themeNames = {
    AppTheme.light: 'Claro',
    AppTheme.dark: 'Oscuro',
    AppTheme.pixel: 'Píxel',
    AppTheme.midnightBlue: 'Medianoche',
  };

  ThemeProvider() {
    _loadPreferences();
  }

  void _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme') ?? AppTheme.pixel.index;
    _currentTheme = AppTheme.values[themeIndex];
    _themeData = _getThemeData(_currentTheme);
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
      // --- MODIFICADO: Se añade el caso para el nuevo tema ---
      case AppTheme.midnightBlue:
        return midnightBlueTheme;
    }
  }
}