import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette
  static const Color _primaryGreen = Color(0xFF00C46A);
  static const Color _textWhite = Colors.white;
  static const Color _textGrey = Color(0xFFD0D7DD);
  static const Color _inputFill = Color.fromRGBO(10, 30, 30, 0.7);
  static const Color _cardBg = Color.fromRGBO(5, 30, 30, 0.7);
  static const Color _borderColor = Color(0xFF36D1A8);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: _primaryGreen,
      // Transparent scaffold to allow the global gradient to show through
      scaffoldBackgroundColor: Colors.transparent,
      
      colorScheme: const ColorScheme.dark(
        primary: _primaryGreen,
        secondary: Color(0xFFF6A623), // Warm amber
        surface: Colors.transparent, 
        onPrimary: _textWhite,
        onSurface: _textWhite,
      ),

      // Typography
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: _textWhite, fontWeight: FontWeight.w800, fontSize: 30),
        headlineMedium: TextStyle(color: _textWhite, fontWeight: FontWeight.bold, fontSize: 26),
        titleLarge: TextStyle(color: _textWhite, fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium: TextStyle(color: _textWhite, fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge: TextStyle(color: _textGrey, fontWeight: FontWeight.normal, fontSize: 16),
        bodyMedium: TextStyle(color: _textGrey, fontWeight: FontWeight.normal, fontSize: 14),
      ),

      // Card Theme (Glassmorphism style)
      cardTheme: CardThemeData(
        color: _cardBg,
        elevation: 0, 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: _borderColor.withOpacity(0.25), width: 1),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // Input Decoration (Text Fields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: Color(0xFFC0CCD3)),
        labelStyle: const TextStyle(color: Color(0xFFC0CCD3)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: const Color(0xFF1E8C7A).withOpacity(0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: const Color(0xFF1E8C7A).withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _primaryGreen, width: 1.5),
        ),
      ),

      // Primary Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryGreen,
          foregroundColor: _textWhite,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          elevation: 8,
          shadowColor: _primaryGreen.withOpacity(0.4),
        ),
      ),

      // Secondary/Ghost Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryGreen,
          side: BorderSide(color: _primaryGreen.withOpacity(0.7), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      
      // Text Buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryGreen,
        ),
      ),

      // App Bar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(color: _textWhite, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: _textWhite),
      ),
      
      // Icons
      iconTheme: const IconThemeData(
        color: _textWhite,
      ),
      
      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _primaryGreen,
        linearTrackColor: Color(0xFF1B262D),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primaryGreen,
        foregroundColor: _textWhite,
      ),
    );
  }
}
