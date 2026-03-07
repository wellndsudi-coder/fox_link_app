import 'package:flutter/material.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';

/// Gera ThemeData baseado nas cores do tenant (White Label).
class WhiteLabelTheme {
  WhiteLabelTheme._();

  /// Constrói ThemeData com primary, secondary e accent do tenant.
  /// Usa [AppTheme.lightTheme] como base e sobrescreve as cores.
  static ThemeData buildTenantTheme({
    required Color primary,
    required Color secondary,
    required Color accent,
  }) {
    final base = AppTheme.lightTheme;
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: secondary,
        tertiary: accent,
      ),
      primaryColor: primary,
    );
  }
}
