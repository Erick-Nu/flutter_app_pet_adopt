import 'package:flutter/material.dart';

class AppTheme {
  // Paleta Naranja (Original)
  static const Color primaryOrange = Color(0xFFFF9800); // Naranja Principal
  static const Color secondaryPeach = Color(0xFFFFF3E0); // Durazno suave (Fondo/Botones secundarios)
  static const Color textDark = Color(0xFF1F1F39);     // Texto oscuro
  static const Color background = Colors.white;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // Definimos el esquema de colores basado en Naranja
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryOrange,
        primary: primaryOrange,
        secondary: secondaryPeach, // Usaremos este para el botón "Sign Up"
        surface: background,
        background: background,
      ),

      scaffoldBackgroundColor: background,

      // Textos
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textDark,
          fontWeight: FontWeight.w900,
          fontSize: 42,
        ),
        headlineSmall: TextStyle(
          color: textDark,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        bodyMedium: TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),
      ),

      // Botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0, // Diseño más plano y limpio
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}