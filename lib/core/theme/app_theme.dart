import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme_presets.dart';

/// Design tokens conforme foxlink-design-studio.
class AppTheme {
  static const Color primaryColor = Color(0xFFFF6A00);
  static const Color primaryDark = Color(0xFFE55A00);
  static const Color backgroundColor = Color(0xFFF3F4F6);
  static const Color cardColor = Colors.white;
  static const Color foregroundColor = Color(0xFF1F2937);
  static const Color secondaryColor = Color(0xFFF1F5F9);
  static const Color mutedForeground = Color(0xFF64748B);
  static const Color accentColor = Color(0xFFFFF7ED);
  static const Color accentForeground = Color(0xFFE55A00);
  static const Color borderColor = Color(0xFFE5E7EB);

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
        surfaceTint: Colors.transparent,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
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
        surfaceTintColor: Colors.transparent,
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
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

  /// Constrói ThemeData a partir de um preset.
  /// O fundo é clareado em ~3-4 tons para um visual mais leve.
  static ThemeData buildThemeFromPreset(ThemePreset preset) {
    final base = lightTheme;
    final bg = Color.lerp(preset.background, Colors.white, 0.08) ?? preset.background;
    final surfaceLow = Color.lerp(bg, preset.surface, 0.5) ?? preset.surface;
    final surfaceHigh = Color.lerp(bg, preset.surface, 0.2) ?? preset.surface;
    return base.copyWith(
      primaryColor: preset.primary,
      scaffoldBackgroundColor: bg,
      colorScheme: base.colorScheme.copyWith(
        primary: preset.primary,
        secondary: preset.secondary,
        tertiary: preset.secondary,
        surface: preset.surface,
        surfaceTint: Colors.transparent,
        surfaceContainerLowest: bg,
        surfaceContainerLow: surfaceLow,
        surfaceContainer: preset.surface,
        surfaceContainerHigh: surfaceHigh,
        surfaceContainerHighest: preset.surface,
        onSurface: preset.textPrimary,
        onSurfaceVariant: preset.textSecondary,
        outline: preset.border,
        outlineVariant: Color.lerp(preset.background, preset.textPrimary, 0.15) ?? preset.border,
      ),
      cardTheme: base.cardTheme.copyWith(
        color: preset.surface,
      ),
      textTheme: base.textTheme.copyWith(
        bodyLarge: base.textTheme.bodyLarge?.copyWith(color: preset.textPrimary),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(color: preset.textSecondary),
        titleLarge: base.textTheme.titleLarge?.copyWith(color: preset.textPrimary),
        titleMedium: base.textTheme.titleMedium?.copyWith(color: preset.textPrimary),
        headlineLarge: base.textTheme.headlineLarge?.copyWith(color: preset.textPrimary),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(color: preset.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: preset.primary,
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
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: preset.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: preset.textPrimary,
        titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(
          color: preset.textPrimary,
        ),
      ),
      dividerTheme: base.dividerTheme.copyWith(
        color: preset.border,
      ),
    );
  }

  static ThemeData get darkTheme {
    const bgDark = Color(0xFF0F172A);
    const surfaceDark = Color(0xFF1E293B);
    const onSurfaceDark = Color(0xFFF1F5F9);
    const onSurfaceVariantDark = Color(0xFF94A3B8);
    const outlineVariantDark = Color(0xFF334155);
    const surfaceContainerDark = Color(0xFF1E293B);
    const surfaceContainerLowDark = Color(0xFF0F172A);
    const surfaceContainerHighDark = Color(0xFF334155);
    const surfaceContainerHighestDark = Color(0xFF475569);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgDark,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryDark,
        error: errorColor,
        surface: surfaceDark,
        onSurface: onSurfaceDark,
        onSurfaceVariant: onSurfaceVariantDark,
        surfaceContainerLowest: bgDark,
        surfaceContainerLow: surfaceContainerLowDark,
        surfaceContainer: surfaceContainerDark,
        surfaceContainerHigh: surfaceContainerHighDark,
        surfaceContainerHighest: surfaceContainerHighestDark,
        outline: outlineVariantDark,
        outlineVariant: outlineVariantDark,
        surfaceTint: Colors.transparent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        surfaceTintColor: Colors.transparent,
        foregroundColor: onSurfaceDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurfaceDark,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerHighestDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        color: outlineVariantDark,
        thickness: 1,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: onSurfaceDark,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurfaceDark,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: onSurfaceDark,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: onSurfaceVariantDark,
        ),
      ),
    );
  }
}
