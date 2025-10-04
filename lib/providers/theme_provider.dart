import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/themes.dart';

// --- NUEVOS TEMAS AÑADIDOS AL ENUM ---
enum AppTheme { 
  light, 
  dark, 
  pixel, 
  whatsappNocturno, // Nombre actualizado para claridad
  brisaPastel,
  classicTerminal,
  telegramDark,
  greenSunset,
}

class ThemeProvider with ChangeNotifier {
  // Por defecto, iniciamos con el tema claro
  ThemeData _themeData = lightTheme;
  AppTheme _currentTheme = AppTheme.light;

  ThemeData get themeData => _themeData;
  AppTheme get currentTheme => _currentTheme;

  // --- NOMBRES ACTUALIZADOS PARA LA UI ---
  final Map<AppTheme, String> themeNames = {
    AppTheme.light: 'Claro (WhatsApp)',
    AppTheme.dark: 'Oscuro (Material)',
    AppTheme.pixel: 'Píxel',
    AppTheme.whatsappNocturno: 'WhatsApp Nocturno',
    AppTheme.brisaPastel: 'Brisa Pastel',
    AppTheme.classicTerminal: 'Terminal Clásica',
    AppTheme.telegramDark: 'Telegram Oscuro',
    AppTheme.greenSunset: 'Atardecer Verde',
  };

  ThemeProvider() {
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    // Se establece el tema claro como valor por defecto si no hay nada guardado
    final themeIndex = prefs.getInt('theme') ?? AppTheme.light.index;
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
      case AppTheme.whatsappNocturno:
        return whatsappNocturnoTheme;
      case AppTheme.brisaPastel:
        return brisaPastelTheme;
      case AppTheme.classicTerminal:
        return classicTerminalTheme;
      // --- NUEVOS TEMAS INTEGARADOS ---
      case AppTheme.telegramDark:
        return telegramDarkTheme;
      case AppTheme.greenSunset:
        return greenSunsetTheme;
      default:
        return lightTheme; // Fallback seguro
    }
  }
}