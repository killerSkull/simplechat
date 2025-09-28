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
  // --- CORRECCIÓN FINAL DIÁLOGO ---
  dialogTheme: DialogThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: const Color.from(alpha: 0, red: 1, green: 1, blue: 1), // Anula la tinta semitransparente
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    titleTextStyle: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
    contentTextStyle: const TextStyle(color: Colors.black87, fontSize: 16),
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: Colors.white,
    textStyle: const TextStyle(color: Colors.black87, fontSize: 24),
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
    textStyle: const TextStyle(color: Colors.white, fontSize: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 8,
  ),
  // --- CORRECCIÓN FINAL DIÁLOGO ---
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFF282828),
    surfaceTintColor: const Color.from(alpha: 0, red: 0.157, green: 0.157, blue: 0.157), // Anula la tinta semitransparente
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
    contentTextStyle: const TextStyle(color: Colors.white70, fontSize: 16),
  ),
);

// --- TEMA MEDIANOCHE (Azul Oscuro y Cian) ---
final ThemeData midnightBlueTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0D1B2A),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF3A86FF),
    primary: const Color(0xFF3A86FF),
    secondary: const Color(0xFF00B4D8),
    onPrimary: Colors.white,
    secondaryContainer: const Color(0xFF1B263B),
    onSecondaryContainer: const Color(0xFFE0E1DD),
    surface: const Color(0xFF1B263B),
    onSurface: const Color(0xFFE0E1DD),
    surfaceVariant: const Color(0xFF415A77),
    background: const Color(0xFF0D1B2A),
    brightness: Brightness.dark,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1B263B),
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    elevation: 1.0,
    color: const Color(0xFF1B263B),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: const Color(0xFF1B263B),
    textStyle: const TextStyle(color: Color(0xFFE0E1DD), fontSize: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 8,
  ),
  // --- CORRECCIÓN FINAL DIÁLOGO ---
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFF1B263B),
    surfaceTintColor: const Color.from(alpha: 0, red: 0.106, green: 0.149, blue: 0.231), // Anula la tinta semitransparente
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    titleTextStyle: const TextStyle(color: Color(0xFFE0E1DD), fontSize: 20, fontWeight: FontWeight.bold),
    contentTextStyle: const TextStyle(color: Color(0xFFE0E1DD), fontSize: 16),
  ),
);

// --- TEMA PIXEL ART ---
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
    surfaceTintColor: Color(0xFF191A21),
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
    textStyle: TextStyle(fontSize: 24),
    shape: BeveledRectangleBorder(),
    elevation: 0,
  ),
);

// --- TEMA TERMINAL CLÁSICA ---
final ThemeData classicTerminalTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF00FF41),
  scaffoldBackgroundColor: const Color(0xFF0D0208),
  fontFamily: 'PressStart2P',
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF00FF41),
    primary: const Color(0xFF00FF41),
    secondary: const Color(0xFF008F11),
    onPrimary: Colors.black,
    secondaryContainer: const Color(0xFF0D1F12),
    onSecondaryContainer: const Color(0xFF00FF41),
    background: const Color(0xFF0D0208),
    surface: const Color(0xFF0D1F12),
    onSurface: const Color(0xFF00FF41),
    surfaceVariant: const Color(0xFF23242F),
    brightness: Brightness.dark,
  ),
  // --- TAMAÑOS DE FUENTE AJUSTADOS ---
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 14.0, color: Color(0xFF00FF41)),
    displayMedium: TextStyle(fontSize: 12.0, color: Color(0xFF00FF41)),
    displaySmall: TextStyle(fontSize: 11.0, color: Color(0xFF00FF41)),
    headlineMedium: TextStyle(fontSize: 10.0, color: Color(0xFF00FF41)),
    headlineSmall: TextStyle(fontSize: 9.0, color: Color(0xFF00FF41)),
    titleLarge: TextStyle(fontSize: 10.0, color: Color(0xFF00FF41)),
    titleMedium: TextStyle(fontSize: 9.0, color: Color(0xFF00FF41)),
    titleSmall: TextStyle(fontSize: 8.0, color: Color(0xFF00FF41)),
    bodyLarge: TextStyle(fontSize: 8.0, color: Color(0xFF00FF41)),
    bodyMedium: TextStyle(fontSize: 7.0, color: Color(0x9900FF41)),
    labelLarge: TextStyle(fontSize: 8.0, color: Color(0xFF00FF41)),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0D1F12),
    foregroundColor: Color(0xFF00FF41),
    elevation: 0,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF00FF41),
    foregroundColor: Colors.black,
    shape: BeveledRectangleBorder(),
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: Color(0xFF0D1F12),
    surfaceTintColor: Color(0xFF0D1F12),
    shape: BeveledRectangleBorder(),
    titleTextStyle: TextStyle(fontFamily: 'PressStart2P', fontSize: 10.0, color: Color(0xFF00FF41)),
    contentTextStyle: TextStyle(fontFamily: 'PressStart2P', fontSize: 9.0, color: Color(0xFF00FF41)),
  ),
  cardTheme: const CardThemeData(
    color: Color(0xFF0D1F12),
    shape: BeveledRectangleBorder(),
  ),
  popupMenuTheme: const PopupMenuThemeData(
    color: Color(0xFF0D1F12),
    textStyle: TextStyle(fontSize: 24),
    shape: BeveledRectangleBorder(),
    elevation: 0,
  ),
);

