import 'package:flutter/material.dart';

/// Configuração de white label por tenant (nome, logo, cores, tema).
class WhiteLabelConfig {
  final String name;
  final String? logoUrl;
  final Color? primaryColor;
  final Color? secondaryColor;
  final Color? accentColor;
  final String? fontFamily;
  /// Nome do preset de tema (ex: 'Beauty Rosa', 'Ocean Blue').
  /// Quando definido, usa tema fixo em vez de cores customizadas.
  final String? themePresetName;

  const WhiteLabelConfig({
    required this.name,
    this.logoUrl,
    this.primaryColor,
    this.secondaryColor,
    this.accentColor,
    this.fontFamily,
    this.themePresetName,
  });

  static String toHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  static Color? parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final cleaned = hex.replaceFirst('#', '').trim();
    if (cleaned.length != 6 && cleaned.length != 8) return null;
    try {
      final value = int.parse(cleaned, radix: 16);
      return Color(cleaned.length == 8 ? value : (0xFF000000 | value));
    } catch (_) {
      return null;
    }
  }

  /// @deprecated Use parseColor
  static Color? parsePrimaryColor(String? hex) => parseColor(hex);
}
