import 'package:flutter/material.dart';

/// Cores centralizadas do tema White Label.
/// Usa Theme.of(context) para refletir as cores do tenant.
class AppColors {
  AppColors._();

  // Cores do tenant (via ColorScheme)
  static Color primary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
  static Color secondary(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;
  static Color accent(BuildContext context) =>
      Theme.of(context).colorScheme.tertiary;
  static Color background(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerLowest;
  static Color card(BuildContext context) =>
      Theme.of(context).colorScheme.surface;
  static Color textPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;
  static Color mutedForeground(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;
  static Color border(BuildContext context) =>
      Theme.of(context).colorScheme.outlineVariant;
  static Color onPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimary;
  static Color fillColor(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;
  static Color accentForeground(BuildContext context) =>
      Theme.of(context).colorScheme.onTertiary;

  // Cores semânticas (fixas por consistência)
  static const Color successColor = Color(0xFF16A34A);
  static const Color warningColor = Color(0xFFF59E0B);

  static Color success(BuildContext context) => successColor;
  static Color warning(BuildContext context) => warningColor;
  static Color error(BuildContext context) =>
      Theme.of(context).colorScheme.error;

  // Aliases para compatibilidade durante migração
  static Color primaryColor(BuildContext context) => primary(context);
  static Color cardColor(BuildContext context) => card(context);
  static Color backgroundColor(BuildContext context) => background(context);
  static Color foregroundColor(BuildContext context) => textPrimary(context);
  static Color borderColor(BuildContext context) => border(context);
  static Color errorColor(BuildContext context) => error(context);
  static Color secondaryColor(BuildContext context) => fillColor(context);
  static Color accentColor(BuildContext context) => accent(context);
}
