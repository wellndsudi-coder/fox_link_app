import 'package:flutter/material.dart';

/// Configuração de white label por tenant (nome, logo, cor principal).
class WhiteLabelConfig {
  final String name;
  final String? logoUrl;
  final Color? primaryColor;

  const WhiteLabelConfig({
    required this.name,
    this.logoUrl,
    this.primaryColor,
  });

  static String toHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  static Color? parsePrimaryColor(String? hex) {
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
}
