import 'package:flutter/material.dart';

import 'package:fox_link_app/core/theme/app_theme.dart';

/// Gera ThemeData baseado nas cores do tenant (White Label).
class WhiteLabelTheme {
  WhiteLabelTheme._();

  /// Constrói ThemeData com primary, secondary, accent e opcionalmente fontFamily e backgroundColor.
  /// Quando backgroundColor é null, usa o tom mais claro da cor secundária.
  static ThemeData buildTenantTheme({
    required Color primary,
    required Color secondary,
    required Color accent,
    Color? backgroundColor,
    String? fontFamily,
  }) {
    final base = AppTheme.lightTheme;
    final baseTextTheme = base.textTheme;
    final textTheme = fontFamily != null && fontFamily.isNotEmpty
        ? _applyFontFamily(baseTextTheme, fontFamily)
        : base.textTheme;

    final rawBg = backgroundColor ?? AppTheme.backgroundColor;
    final bg = Color.lerp(rawBg, Colors.white, 0.08) ?? rawBg;
    final surface = Colors.white;
    final surfaceLow = Color.lerp(bg, surface, 0.5) ?? surface;
    final surfaceHigh = Color.lerp(bg, surface, 0.2) ?? surface;

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: secondary,
        tertiary: accent,
        surface: surface,
        surfaceTint: Colors.transparent,
        surfaceContainerLowest: bg,
        surfaceContainerLow: surfaceLow,
        surfaceContainer: surface,
        surfaceContainerHigh: surfaceHigh,
        surfaceContainerHighest: surface,
        onSurface: base.colorScheme.onSurface,
        onSurfaceVariant: base.colorScheme.onSurfaceVariant,
        outline: Color.lerp(bg, Colors.black, 0.12) ?? base.colorScheme.outline,
        outlineVariant: Color.lerp(bg, Colors.black, 0.06) ?? base.colorScheme.outlineVariant,
      ),
      primaryColor: primary,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: base.colorScheme.onSurface,
        titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(
          color: base.colorScheme.onSurface,
        ),
      ),
      cardTheme: base.cardTheme.copyWith(color: surface),
      textTheme: textTheme,
    );
  }

  static TextTheme _applyFontFamily(TextTheme base, String fontFamily) {
    return TextTheme(
      displayLarge: base.displayLarge?.copyWith(fontFamily: fontFamily),
      displayMedium: base.displayMedium?.copyWith(fontFamily: fontFamily),
      displaySmall: base.displaySmall?.copyWith(fontFamily: fontFamily),
      headlineLarge: base.headlineLarge?.copyWith(fontFamily: fontFamily),
      headlineMedium: base.headlineMedium?.copyWith(fontFamily: fontFamily),
      headlineSmall: base.headlineSmall?.copyWith(fontFamily: fontFamily),
      titleLarge: base.titleLarge?.copyWith(fontFamily: fontFamily),
      titleMedium: base.titleMedium?.copyWith(fontFamily: fontFamily),
      titleSmall: base.titleSmall?.copyWith(fontFamily: fontFamily),
      bodyLarge: base.bodyLarge?.copyWith(fontFamily: fontFamily),
      bodyMedium: base.bodyMedium?.copyWith(fontFamily: fontFamily),
      bodySmall: base.bodySmall?.copyWith(fontFamily: fontFamily),
      labelLarge: base.labelLarge?.copyWith(fontFamily: fontFamily),
      labelMedium: base.labelMedium?.copyWith(fontFamily: fontFamily),
      labelSmall: base.labelSmall?.copyWith(fontFamily: fontFamily),
    );
  }
}
