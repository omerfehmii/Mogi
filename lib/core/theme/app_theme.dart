import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Font stilleri
  static final TextTheme _baseTextTheme = TextTheme(
    displayLarge: GoogleFonts.nunitoSans(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
    ),
    displayMedium: GoogleFonts.nunitoSans(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
    ),
    displaySmall: GoogleFonts.nunitoSans(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.25,
    ),
    headlineLarge: GoogleFonts.nunitoSans(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.25,
    ),
    headlineMedium: GoogleFonts.nunitoSans(
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: GoogleFonts.nunitoSans(
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: GoogleFonts.nunitoSans(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
    ),
    titleMedium: GoogleFonts.nunitoSans(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    titleSmall: GoogleFonts.nunitoSans(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    bodyLarge: GoogleFonts.nunitoSans(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.15,
    ),
    bodyMedium: GoogleFonts.nunitoSans(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.25,
    ),
    bodySmall: GoogleFonts.nunitoSans(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.4,
    ),
    labelLarge: GoogleFonts.nunitoSans(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    labelMedium: GoogleFonts.nunitoSans(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    labelSmall: GoogleFonts.nunitoSans(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
  );

  static TextTheme _getLightTextTheme() {
    return _baseTextTheme;
  }

  static TextTheme _getDarkTextTheme() {
    return _baseTextTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    );
  }

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.light,
    ),
    textTheme: _getLightTextTheme(),
    fontFamily: GoogleFonts.nunitoSans().fontFamily,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      titleTextStyle: GoogleFonts.nunitoSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.nunitoSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.dark,
    ),
    textTheme: _getDarkTextTheme(),
    fontFamily: GoogleFonts.nunitoSans().fontFamily,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      titleTextStyle: GoogleFonts.nunitoSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.nunitoSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
  );
} 