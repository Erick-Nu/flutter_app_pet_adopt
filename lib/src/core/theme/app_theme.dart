import 'package:flutter/material.dart';

class AppTheme {
  // Color principal (Naranja PetAdopt)
  static const Color primaryColor = Color(0xFFFF9800); // Naranja vibrante
  static const Color secondaryColor = Color(0xFFFFF3E0); // Naranja muy suave (fondo)
  static const Color accentColor = Color(0xFFFF5722); // Naranja rojizo para acciones

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        surface: Colors.white,
        background: secondaryColor,
      ),
      
      // Estilo global de botones
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Bordes muy redondeados
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),

      // Estilo global de Inputs (Cajas de texto)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        prefixIconColor: Colors.grey,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    );
  }
}