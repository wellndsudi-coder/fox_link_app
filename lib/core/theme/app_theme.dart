import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens conforme foxlink-design-studio.
class AppTheme {
  static const Color primaryColor = Color(0xFFF97316);
  static const Color primaryDark = Color(0xFFC2410C);
  static const Color backgroundColor = Color(0xFFFCFCFC);
  static const Color cardColor = Colors.white;
  static const Color foregroundColor = Color(0xFF1E293B);
  static const Color secondaryColor = Color(0xFFF1F5F9);
  static const Color mutedForeground = Color(0xFF64748B);
  static const Color accentColor = Color(0xFFFFF7ED);
  static const Color accentForeground = Color(0xFFC2410C);
  static const Color borderColor = Color(0xFFE2E8F0);

  static const Color successColor = Color(0xFF16A34A);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFDC2626);

  static const double borderRadius = 12;
  static const double borderRadiusMd = 10;
  static const double borderRadiusSm = 8;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,

      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: primaryDark,
        error: errorColor,
        surface: cardColor,
        onSurface: foregroundColor,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: foregroundColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: foregroundColor,
        ),
      ),

      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: secondaryColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide.none,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),

      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF1E293B),
        contentTextStyle: TextStyle(color: Colors.white),
      ),

      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
      ),

      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: foregroundColor,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: foregroundColor,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: foregroundColor,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: mutedForeground,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
    );
  }
}
