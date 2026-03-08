import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';

/// Horizontal date carousel with 7-14 days from today.
/// Each chip shows weekday, day, month. Selected state with scroll to selection.
class DateCarousel extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final int daysAhead;

  const DateCarousel({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.daysAhead = 14,
  });

  /// Retorna datas a partir do domingo da semana atual (cada "role" = semana inteira).
  List<DateTime> get _dates {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Dart: weekday 1=segunda..7=domingo. Voltar ao domingo da semana.
    final weekday = today.weekday;
    final daysToSunday = weekday == 7 ? 0 : weekday;
    final startOfWeek = today.subtract(Duration(days: daysToSunday));
    return List.generate(daysAhead, (i) => startOfWeek.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final dates = _dates;
    final scrollController = ScrollController();

    return SizedBox(
      height: 92,
      child: ListView.builder(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = selectedDate != null &&
              selectedDate!.year == date.year &&
              selectedDate!.month == date.month &&
              selectedDate!.day == date.day;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _DateChip(
              date: date,
              isSelected: isSelected,
              onTap: () => onDateSelected(date),
            ),
          );
        },
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateChip({
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekdayFormat = DateFormat('EEE', 'pt_BR');
    final dayFormat = DateFormat('d');
    final monthFormat = DateFormat('MMM', 'pt_BR');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : AppColors.border(context),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                weekdayFormat.format(date),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : AppColors.mutedForeground(context),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              Text(
                dayFormat.format(date),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
              ),
              Text(
                monthFormat.format(date),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: isSelected
                      ? theme.colorScheme.onPrimary.withValues(alpha: 0.9)
                      : AppColors.mutedForeground(context),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
