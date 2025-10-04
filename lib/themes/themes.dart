import 'package:flutter/material.dart';

// --- TEMA CLARO (Estilo WhatsApp Pulido) ---
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: const Color(0xFF008069),
  scaffoldBackgroundColor: const Color(0xFFF0F2F5),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF008069),
    primary: const Color(0xFF008069),
    secondary: const Color(0xFF00A884),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFFFFFFF),
    onSecondaryContainer: Colors.black87,
    background: const Color(0xFFF0F2F5),
    surface: Colors.white,
    onSurface: Colors.black87,
    surfaceVariant: const Color(0xFFE6E6E6),
    brightness: Brightness.light,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF008069),
    foregroundColor: Colors.white,
    elevation: 2.0,
    titleTextStyle: TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.w500,
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF00A884),
    foregroundColor: Colors.white,
  ),
  cardTheme: CardThemeData(
    elevation: 1.0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    titleTextStyle: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
    contentTextStyle: const TextStyle(color: Colors.black87, fontSize: 16),
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: Colors.white,
    textStyle: const TextStyle(color: Colors.black87),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 8,
  ),
);

// --- TEMA OSCURO (Material 3 Moderno) ---
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF7B96EB),
    brightness: Brightness.dark,
    primary: const Color(0xFF82B1FF),
    onPrimary: const Color(0xFF00227B),
    secondaryContainer: const Color(0xFF333846),
    onSecondaryContainer: const Color(0xFFE0E2EC),
    background: const Color(0xFF1B1B1F),
    surface: const Color(0xFF24262E),
    onSurface: const Color(0xFFE3E2E6),
  ),
  scaffoldBackgroundColor: const Color(0xFF1B1B1F),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF24262E),
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    elevation: 1.0,
    color: const Color(0xFF24262E),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: const Color(0xFF2F313A),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 8,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFF24262E),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    titleTextStyle: const TextStyle(color: Color(0xFFE3E2E6), fontSize: 20, fontWeight: FontWeight.bold),
    contentTextStyle: const TextStyle(color: Color(0xFFE3E2E6), fontSize: 16),
  ),
);

// --- TEMA WHATSAPP NOCTURNO ---
final ThemeData whatsappNocturnoTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF00A884),
  scaffoldBackgroundColor: const Color(0xFF111B21),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF005C4B),
    onPrimary: Colors.white,
    secondaryContainer: Color(0xFF202C33),
    onSecondaryContainer: Colors.white,
    background: Color(0xFF111B21),
    surface: Color(0xFF202C33),
    onSurface: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF202C33),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF00A884),
    foregroundColor: Colors.white,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: const Color(0xFF202C33),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFF202C33),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: const Color(0xFF202C33),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
);

// --- TEMA BRISA PASTEL ---
final ThemeData brisaPastelTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFFDF6F0),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF8E9AAF),
    brightness: Brightness.light,
    primary: const Color(0xFFB4C2D4),
    onPrimary: const Color(0xFF333740),
    secondaryContainer: const Color(0xFFEAE5E0),
    onSecondaryContainer: const Color(0xFF59524C),
    surface: const Color(0xFFF8F0E9),
    onSurface: const Color(0xFF45403B),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF8F0E9),
    foregroundColor: Color(0xFF45403B),
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: const Color(0xFFF8F0E9),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    surfaceTintColor: Colors.transparent,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFFFDF6F0),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
);

// --- TEMA TERMINAL CLÁSICA ---
final ThemeData classicTerminalTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF00FF41),
  scaffoldBackgroundColor: const Color(0xFF0D0208),
  fontFamily: 'CourierPrime',
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF00FF41),
    brightness: Brightness.dark,
    primary: const Color(0xFF00FF41),
    onPrimary: Colors.black,
    secondaryContainer: const Color(0xFF1A1A1A),
    onSecondaryContainer: const Color(0xFF00FF41),
    background: const Color(0xFF0D0208),
    surface: const Color(0xFF1A1A1A),
    onSurface: const Color(0xFF00FF41),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color(0xFF00FF41)),
    bodyMedium: TextStyle(color: Color(0xFF00FF41)),
    titleLarge: TextStyle(color: Color(0xFF00FF41)),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1A1A1A),
    foregroundColor: Color(0xFF00FF41),
    elevation: 0,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: Color(0xFF1A1A1A),
    shape: RoundedRectangleBorder(side: BorderSide(color: Color(0xFF00FF41))),
  ),
  cardTheme: const CardThemeData(
    color: Color(0xFF1A1A1A),
    shape: RoundedRectangleBorder(side: BorderSide(color: Color(0xFF00FF41), width: 0.5)),
  ),
);

// --- TEMA 1: TELEGRAM OSCURO (REFINADO) ---
final ThemeData telegramDarkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF212121), // Gris oscuro de fondo
  primaryColor: const Color(0xFFeb5757), // Acento rojo/naranja
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFeb5757), // Color para acentos interactivos (controles de audio)
    onPrimary: Colors.white,
    secondaryContainer: Color(0xFF333333), // Burbujas de chat
    onSecondaryContainer: Colors.white,
    background: Color(0xFF212121),
    surface: Color(0xFF303030), // AppBars, tarjetas
    onSurface: Colors.white,
    primaryContainer: Color(0xFFeb5757), // Badges de notificación
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF303030),
    elevation: 0,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFFeb5757), // Botón de acción
    foregroundColor: Colors.white,
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF303030),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFF303030),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);

// --- TEMA 2: ATARDECER VERDE ---
final ThemeData greenSunsetTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0e1613),
  primaryColor: const Color(0xFF25d366),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF2a3942), // Burbujas de chat
    onPrimary: Colors.white,
    secondary: Color(0xFF25d366), // Acento principal
    secondaryContainer: Color(0xFF2a3942),
    onSecondaryContainer: Colors.white,
    background: Color(0xFF0e1613),
    surface: Color(0xFF1f2c34), // AppBar, tarjetas
    onSurface: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1f2c34),
    elevation: 0,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF25d366),
    foregroundColor: Colors.white,
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF1f2c34),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFF1f2c34),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
);

// --- TEMA PIXEL ART (SE MANTIENE) ---
// (Tu tema pixel art original se mantiene aquí sin cambios)
final ThemeData pixelTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: const Color(0xFF23242F),
  fontFamily: 'PressStart2P',
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF5E60CE),
    brightness: Brightness.dark,
    secondaryContainer: const Color(0xFF3A3B4A),
    onSecondaryContainer: Colors.white,
    surface: const Color(0xFF191A21),
    onSurface: Colors.white,
  ),
  // --- TAMAÑOS DE FUENTE AJUSTADOS ---
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 10.0),
    displayMedium: TextStyle(fontSize: 9.0),
    displaySmall: TextStyle(fontSize: 8.0),
    headlineMedium: TextStyle(fontSize: 8.0),
    headlineSmall: TextStyle(fontSize: 7.0),
    titleLarge: TextStyle(fontSize: 10.0), // Usado en AppBars
    titleMedium: TextStyle(fontSize: 9.0),
    titleSmall: TextStyle(fontSize: 8.0),
    bodyLarge: TextStyle(fontSize: 8.0), // Texto principal
    bodyMedium: TextStyle(fontSize: 7.0), // Texto secundario
    labelLarge: TextStyle(fontSize: 6.0), // Botones
    bodySmall: TextStyle(fontSize: 4.0), // Texto más pequeño
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF191A21),
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: const Color(0xFF5E60CE),
      shape: const BeveledRectangleBorder(),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      textStyle: const TextStyle(fontFamily: 'PressStart2P', fontSize: 8),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF5E60CE),
    shape: BeveledRectangleBorder(),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: Colors.white54),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: Color(0xFF5E60CE)),
    ),
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: Color(0xFF191A21),
    surfaceTintColor: Colors.transparent,
    shape: BeveledRectangleBorder(),
    titleTextStyle: TextStyle(fontFamily: 'PressStart2P', fontSize: 10.0),
    contentTextStyle: TextStyle(fontFamily: 'PressStart2P', fontSize: 9.0),
  ),
  cardTheme: const CardThemeData(
    color: Color(0xFF191A21),
    shape: BeveledRectangleBorder(),
  ),
  popupMenuTheme: const PopupMenuThemeData(
    color: Color(0xFF191A21),
    shape: BeveledRectangleBorder(),
    elevation: 0,
  ),
);