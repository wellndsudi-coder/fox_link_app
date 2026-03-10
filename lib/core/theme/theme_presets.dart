import 'package:flutter/material.dart';

/// Preset de tema com cores profissionais e combinações garantidas.
class ThemePreset {
  final String name;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  const ThemePreset({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
  });
}

/// Catálogo de temas SaaS profissionais.
class ThemePresets {
  ThemePresets._();

  static const List<ThemePreset> all = [
    ThemePreset(
      name: 'Fox Laranja',
      primary: Color(0xFFFF6A00),
      secondary: Color(0xFFFFB067),
      background: Color(0xFFF3F4F6),
      surface: Colors.white,
      textPrimary: Color(0xFF1F2937),
      textSecondary: Color(0xFF6B7280),
      border: Color(0xFFE5E7EB),
    ),
    ThemePreset(
      name: 'SaaS Azul',
      primary: Color(0xFF2563EB),
      secondary: Color(0xFF60A5FA),
      background: Color(0xFFF4F6FA),
      surface: Colors.white,
      textPrimary: Color(0xFF111827),
      textSecondary: Color(0xFF6B7280),
      border: Color(0xFFE5E7EB),
    ),
    ThemePreset(
      name: 'Verde Natural',
      primary: Color(0xFF10B981),
      secondary: Color(0xFF6EE7B7),
      background: Color(0xFFF4F5F6),
      surface: Colors.white,
      textPrimary: Color(0xFF111827),
      textSecondary: Color(0xFF6B7280),
      border: Color(0xFFE5E7EB),
    ),
    ThemePreset(
      name: 'Beauty Rosa',
      primary: Color(0xFFEC4899),
      secondary: Color(0xFFF9A8D4),
      background: Color(0xFFFEF5F9),
      surface: Colors.white,
      textPrimary: Color(0xFF1F2937),
      textSecondary: Color(0xFF6B7280),
      border: Color(0xFFF3E8FF),
    ),
    ThemePreset(
      name: 'Premium Roxo',
      primary: Color(0xFF7C3AED),
      secondary: Color(0xFFC4B5FD),
      background: Color(0xFFF4F5F6),
      surface: Colors.white,
      textPrimary: Color(0xFF111827),
      textSecondary: Color(0xFF6B7280),
      border: Color(0xFFE5E7EB),
    ),
    ThemePreset(
      name: 'Impacto Vermelho',
      primary: Color(0xFFEF4444),
      secondary: Color(0xFFFCA5A5),
      background: Color(0xFFFEF5F5),
      surface: Colors.white,
      textPrimary: Color(0xFF111827),
      textSecondary: Color(0xFF6B7280),
      border: Color(0xFFFEE2E2),
    ),
    ThemePreset(
      name: 'Corporativo Cinza',
      primary: Color(0xFF374151),
      secondary: Color(0xFF9CA3AF),
      background: Color(0xFFF4F5F6),
      surface: Colors.white,
      textPrimary: Color(0xFF111827),
      textSecondary: Color(0xFF6B7280),
      border: Color(0xFFE5E7EB),
    ),
    ThemePreset(
      name: 'Ocean Blue',
      primary: Color(0xFF0284C7),
      secondary: Color(0xFF7DD3FC),
      background: Color(0xFFF6FBFF),
      surface: Colors.white,
      textPrimary: Color(0xFF0F172A),
      textSecondary: Color(0xFF64748B),
      border: Color(0xFFE2E8F0),
    ),
    ThemePreset(
      name: 'Emerald Pro',
      primary: Color(0xFF059669),
      secondary: Color(0xFF34D399),
      background: Color(0xFFF4FEFB),
      surface: Colors.white,
      textPrimary: Color(0xFF064E3B),
      textSecondary: Color(0xFF6B7280),
      border: Color(0xFFD1FAE5),
    ),
    ThemePreset(
      name: 'Lavender Tech',
      primary: Color(0xFF8B5CF6),
      secondary: Color(0xFFC4B5FD),
      background: Color(0xFFF7F5FE),
      surface: Colors.white,
      textPrimary: Color(0xFF1F2937),
      textSecondary: Color(0xFF6B7280),
      border: Color(0xFFEDE9FE),
    ),
    ThemePreset(
      name: 'Minimal Black',
      primary: Color(0xFF111827),
      secondary: Color(0xFF4B5563),
      background: Color(0xFFF4F5F6),
      surface: Colors.white,
      textPrimary: Color(0xFF111827),
      textSecondary: Color(0xFF6B7280),
      border: Color(0xFFE5E7EB),
    ),
    ThemePreset(
      name: 'Gold Luxury',
      primary: Color(0xFFD97706),
      secondary: Color(0xFFFCD34D),
      background: Color(0xFFFFFBF0),
      surface: Colors.white,
      textPrimary: Color(0xFF1C1917),
      textSecondary: Color(0xFF78716C),
      border: Color(0xFFFDE68A),
    ),
  ];

  static ThemePreset getPresetByName(String name) {
    return all.firstWhere(
      (preset) => preset.name == name,
      orElse: () => all.first,
    );
  }
}

/// Retorna o preset pelo nome. Se não encontrar, retorna o primeiro.
ThemePreset getPresetByName(String name) {
  return ThemePresets.getPresetByName(name);
}
