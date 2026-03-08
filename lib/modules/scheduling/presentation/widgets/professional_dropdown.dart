import 'package:flutter/material.dart';

import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';

/// Premium professional selection dropdown for scheduling.
class ProfessionalDropdown extends StatelessWidget {
  final String? selectedProfessionalId;
  final List<Map<String, dynamic>> professionals;
  final ValueChanged<String?> onChanged;

  const ProfessionalDropdown({
    super.key,
    required this.selectedProfessionalId,
    required this.professionals,
    required this.onChanged,
  });

  String? _getName(String id) {
    try {
      return professionals.firstWhere((p) => p['id'] == id)['name'] as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = selectedProfessionalId != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : AppColors.border(context),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedProfessionalId,
          isExpanded: true,
          hint: Text(
            'Selecione o profissional',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.mutedForeground(context),
            ),
          ),
          dropdownColor: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          items: professionals.map((p) {
            final id = p['id'] as String?;
            final name = p['name'] as String? ?? 'Profissional';
            if (id == null) return const DropdownMenuItem<String>(value: null, child: SizedBox.shrink());
            return DropdownMenuItem<String>(
              value: id,
              child: Text(
                name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
