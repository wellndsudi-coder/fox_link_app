import 'package:flutter/material.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';

class TodayOverviewCard extends StatelessWidget {
  final int appointmentsToday;
  final int totalSlots;

  const TodayOverviewCard({
    super.key,
    required this.appointmentsToday,
    required this.totalSlots,
  });

  int get _occupancyPercent {
    const capacityMinutes = 8 * 60;
    final bookedMinutes = totalSlots * 30;
    return ((bookedMinutes / capacityMinutes) * 100).clamp(0, 100).round();
  }

  int get _freeSlots => (20 - totalSlots).clamp(0, 99);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visão geral de hoje',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  value: '$totalSlots',
                  label: 'agendamentos',
                ),
              ),
              Expanded(
                child: _StatItem(
                  value: '$_occupancyPercent%',
                  label: 'ocupação',
                ),
              ),
              Expanded(
                child: _StatItem(
                  value: '$_freeSlots',
                  label: 'horários livres',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.mutedForeground(context),
          ),
        ),
      ],
    );
  }
}
