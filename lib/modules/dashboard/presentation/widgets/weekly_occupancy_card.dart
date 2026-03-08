import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_tenant_weekly_occupation_usecase.dart';

class WeeklyOccupancyCard extends StatelessWidget {
  final List<DayOccupation> data;

  const WeeklyOccupancyCard({
    super.key,
    required this.data,
  });

  String _weekdayName(DateTime d) {
    return DateFormat.E('pt_BR').format(d).substring(0, 3);
  }

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
            'Ocupação semanal',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (data.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Nenhum dado este mês',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedForeground(context),
                  ),
                ),
              ),
            )
          else
            ...data.map((d) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        child: Text(
                          _weekdayName(d.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedForeground(context),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (d.occupancyPercent / 100).clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: AppColors.fillColor(context),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary(context),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${d.occupancyPercent.round()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
        ],
      ),
    );
  }
}
