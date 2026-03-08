import 'package:flutter/material.dart';

import 'package:fox_link_app/core/theme/app_theme.dart';

/// Gera ThemeData baseado nas cores do tenant (White Label).
class WhiteLabelTheme {
  WhiteLabelTheme._();

  /// Constrói ThemeData com primary, secondary, accent e opcionalmente fontFamily.
  /// Usa [AppTheme.lightTheme] como base e sobrescreve as cores e tipografia.
  static ThemeData buildTenantTheme({
    required Color primary,
    required Color secondary,
    required Color accent,
    String? fontFamily,
  }) {
    final base = AppTheme.lightTheme;
    final baseTextTheme = base.textTheme;
    final textTheme = fontFamily != null && fontFamily.isNotEmpty
        ? _applyFontFamily(baseTextTheme, fontFamily)
        : base.textTheme;

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: secondary,
        tertiary: accent,
      ),
      primaryColor: primary,
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
