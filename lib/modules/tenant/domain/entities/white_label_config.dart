import 'package:flutter/material.dart';

/// Configuração de white label por tenant (nome, logo, cores).
class WhiteLabelConfig {
  final String name;
  final String? logoUrl;
  final Color? primaryColor;
  final Color? secondaryColor;
  final Color? accentColor;
  final String? fontFamily;

  const WhiteLabelConfig({
    required this.name,
    this.logoUrl,
    this.primaryColor,
    this.secondaryColor,
    this.accentColor,
    this.fontFamily,
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
