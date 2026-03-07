import 'package:flutter/material.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
/// Cores disponíveis para o salão (design FoxLink Studio).
final List<Color> _salonColors = [
  const Color(0xFFF97316), // Primary orange
  const Color(0xFF2563EB), // Blue
  const Color(0xFF16A34A), // Green
  const Color(0xFFEC4899), // Pink
  const Color(0xFF8B5CF6), // Purple
  const Color(0xFFEF4444), // Red
];

/// Card de seleção de cor do salão para white label.
class SalonColorCard extends StatelessWidget {
  final Color? selectedColor;
  final ValueChanged<Color> onColorSelected;

  const SalonColorCard({
    super.key,
    this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final effectiveSelected = selectedColor ?? primaryColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cor do salão',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Escolha a cor principal do seu salão',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _salonColors.map((color) {
              final isSelected = _colorMatches(effectiveSelected, color);
              return GestureDetector(
                onTap: () => onColorSelected(color),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? color.withValues(alpha: 0.8)
                          : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  bool _colorMatches(Color a, Color b) {
    return a.value == b.value;
  }
}
