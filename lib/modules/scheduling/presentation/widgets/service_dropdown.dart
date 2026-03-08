import 'package:flutter/material.dart';

import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/modules/services/domain/entities/service.dart';

/// Premium service selection dropdown for scheduling.
class ServiceDropdown extends StatelessWidget {
  final Service? selectedService;
  final List<Service> services;
  final ValueChanged<Service?> onChanged;

  const ServiceDropdown({
    super.key,
    required this.selectedService,
    required this.services,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = selectedService != null;

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
        child: DropdownButton<Service>(
          value: selectedService,
          isExpanded: true,
          hint: Text(
            'Selecione o serviço',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.mutedForeground(context),
            ),
          ),
          dropdownColor: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          items: services.map((s) {
            return DropdownMenuItem<Service>(
              value: s,
              child: Text(
                '${s.name.value} — ${s.baseDuration.minutes} min',
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
