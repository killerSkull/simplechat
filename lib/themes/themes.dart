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
  // --- CORREGIDO: Usando CardThemeData ---
  cardTheme: CardThemeData(
    elevation: 1.0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  // --- CORREGIDO: Usando DialogThemeData ---
  dialogTheme: DialogThemeData(
     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
);

// --- TEMA OSCURO (Material 3 Moderno) ---
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepPurple, 
    brightness: Brightness.dark
  ),
  scaffoldBackgroundColor: const Color(0xFF121212),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1F1F1F),
    elevation: 0,
  ),
   // --- CORREGIDO: Usando CardThemeData ---
   cardTheme: CardThemeData(
    elevation: 1.0,
    color: const Color(0xFF1F1F1F),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  // --- CORREGIDO: Usando DialogThemeData ---
  dialogTheme: DialogThemeData(
     backgroundColor: const Color(0xFF282828),
     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
);

// --- NUEVO: TEMA MEDIANOCHE (Azul Oscuro y Cian) ---
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
    surfaceVariant: const Color(0xFF415A77),
    background: const Color(0xFF0D1B2A),
    brightness: Brightness.dark,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1B263B), 
    elevation: 0,
  ),
   // --- CORREGIDO: Usando CardThemeData ---
   cardTheme: CardThemeData(
    elevation: 1.0,
    color: const Color(0xFF1B263B),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  // --- CORREGIDO: Usando DialogThemeData ---
  dialogTheme: DialogThemeData(
     backgroundColor: const Color(0xFF1B263B),
     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
);

// --- TEMA PÍXEL (Fiel al estilo retro) ---
final ThemeData pixelTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: const Color(0xFF23242F),
  fontFamily: 'PressStart2P',
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF5E60CE), 
    brightness: Brightness.dark
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(fontSize: 10.0, color: Colors.white),
    bodyMedium: TextStyle(fontSize: 9.0, color: Colors.white70),
    titleLarge: TextStyle(fontSize: 12.0),
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
  // --- CORREGIDO: Usando DialogThemeData ---
  dialogTheme: const DialogThemeData(
    backgroundColor: Color(0xFF191A21),
    shape: BeveledRectangleBorder(),
  ),
  // --- CORREGIDO: Usando CardThemeData ---
  cardTheme: const CardThemeData(
    color: Color(0xFF191A21),
    shape: BeveledRectangleBorder(),
  )
);