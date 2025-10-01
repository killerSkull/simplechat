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
    secondaryContainer: const Color(0xFFE6FFD9), // Burbuja de mensaje recibido
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
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
      surfaceContainer: const Color(0xFF282828)),
  scaffoldBackgroundColor: const Color(0xFF121212),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1F1F1F),
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    elevation: 1.0,
    color: const Color(0xFF1F1F1F),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: const Color(0xFF282828),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 8,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFF282828),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
    contentTextStyle: const TextStyle(color: Colors.white70, fontSize: 16),
  ),
);

// --- TEMA WHATSAPP NOCTURNO (NUEVO) ---
final ThemeData whatsAppNocturnoTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF00A884),
  scaffoldBackgroundColor: const Color(0xFF111B21),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF00A884),
    brightness: Brightness.dark,
    primary: const Color(0xFF00A884), // Verde principal para botones
    onPrimary: Colors.black,
    secondaryContainer: const Color(0xFF202C33), // Burbuja de mensaje recibido
    onSecondaryContainer: Colors.white,
    surface: const Color(0xFF202C33),
    onSurface: Colors.white,
    background: const Color(0xFF111B21),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF202C33),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF00A884),
    foregroundColor: Colors.black,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: const Color(0xFF111B21), // Mismo color que el fondo para un look integrado
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFF202C33),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: const Color(0xFF202C33),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);

// --- TEMA BRISA PASTEL (NUEVO) ---
final ThemeData brisaPastelTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: const Color(0xFF81C784), // Verde pastel
  scaffoldBackgroundColor: const Color(0xFFF1F8E9), // Fondo muy claro
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF81C784),
    brightness: Brightness.light,
    primary: const Color(0xFF81C784),
    onPrimary: Colors.white,
    secondaryContainer: const Color(0xFFE1BEE7), // Burbuja lila pastel
    onSecondaryContainer: const Color(0xFF4A148C),
    surface: Colors.white,
    onSurface: Colors.black87,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black87,
    elevation: 1,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF81C784),
    foregroundColor: Colors.white,
  ),
  cardTheme: CardThemeData(
    elevation: 1.0,
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);


// --- TEMA TERMINAL CLÁSICA (REFINADO) ---
final ThemeData classicTerminalTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF00FF41),
  scaffoldBackgroundColor: const Color(0xFF0D0208),
  fontFamily: 'RobotoMono', // Una fuente monoespaciada más legible
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF00FF41),
    primary: const Color(0xFF00FF41),
    secondary: const Color(0xFF008F11),
    onPrimary: Colors.black,
    secondaryContainer: const Color(0xAA0D1F12),
    onSecondaryContainer: const Color(0xFF00FF41),
    background: const Color(0xFF0D0208),
    surface: const Color(0xFF0D1F12),
    onSurface: const Color(0xFF00FF41),
    surfaceVariant: const Color(0xFF23242F),
    brightness: Brightness.dark,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color(0xFF00FF41)),
    bodyMedium: TextStyle(color: Color(0x9900FF41)),
    titleLarge: TextStyle(color: Color(0xFF00FF41)),
    headlineSmall: TextStyle(color: Color(0xFF00FF41)),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0D1F12),
    foregroundColor: Color(0xFF00FF41),
    elevation: 0,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF00FF41),
    foregroundColor: Colors.black,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: Color(0xFF0D1F12),
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(fontFamily: 'RobotoMono', color: Color(0xFF00FF41)),
    contentTextStyle: TextStyle(fontFamily: 'RobotoMono', color: Color(0xFF00FF41)),
  ),
  cardTheme: const CardThemeData(
    color: Color(0xFF0D1F12),
  ),
  popupMenuTheme: const PopupMenuThemeData(
    color: Color(0xFF0D1F12),
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
    displayLarge: TextStyle(fontSize: 14.0),
    displayMedium: TextStyle(fontSize: 12.0),
    displaySmall: TextStyle(fontSize: 11.0),
    headlineMedium: TextStyle(fontSize: 10.0),
    headlineSmall: TextStyle(fontSize: 9.0),
    titleLarge: TextStyle(fontSize: 10.0), // Usado en AppBars
    titleMedium: TextStyle(fontSize: 9.0),
    titleSmall: TextStyle(fontSize: 8.0),
    bodyLarge: TextStyle(fontSize: 8.0), // Texto principal
    bodyMedium: TextStyle(fontSize: 7.0), // Texto secundario
    labelLarge: TextStyle(fontSize: 8.0), // Botones
    bodySmall: TextStyle(fontSize: 6.0), // Texto más pequeño
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