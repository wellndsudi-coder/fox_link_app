import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';

/// Premium date selector for scheduling.
class DateSelector extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onTap;

  const DateSelector({
    super.key,
    required this.selectedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = selectedDate != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: isSelected ? theme.colorScheme.primary : AppColors.mutedForeground(context),
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Data',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.mutedForeground(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedDate != null
                          ? DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(selectedDate!)
                          : 'Selecione a data',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: selectedDate != null ? theme.colorScheme.onSurface : AppColors.mutedForeground(context),
                        fontWeight: selectedDate != null ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.mutedForeground(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
