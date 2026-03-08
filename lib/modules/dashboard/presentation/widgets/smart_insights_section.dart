import 'package:flutter/material.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_admin_metrics_usecase.dart';

class SmartInsightsSection extends StatelessWidget {
  final AdminMetrics metrics;
  final int totalSlots;

  const SmartInsightsSection({
    super.key,
    required this.metrics,
    required this.totalSlots,
  });

  int get _freeSlots => (20 - totalSlots).clamp(0, 99);

  @override
  Widget build(BuildContext context) {
    final insights = <_Insight>[];

    if (_freeSlots > 0) {
      insights.add(_Insight(
        icon: Icons.schedule,
        message: '$_freeSlots horários ainda livres hoje',
      ));
    }

    if (metrics.revenueTrend != null && metrics.revenueTrend!.startsWith('+')) {
      insights.add(_Insight(
        icon: Icons.trending_up,
        message: 'Faturamento hoje maior que ontem',
      ));
    }

    if (totalSlots >= 15) {
      insights.add(_Insight(
        icon: Icons.local_fire_department,
        message: 'Hoje está bem cheio',
      ));
    }

    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: insights
              .map((i) => _InsightChip(icon: i.icon, message: i.message))
              .toList(),
        ),
      ],
    );
  }
}

class _Insight {
  final IconData icon;
  final String message;

  _Insight({required this.icon, required this.message});
}

class _InsightChip extends StatelessWidget {
  final IconData icon;
  final String message;

  const _InsightChip({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.fillColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primary(context)),
          const SizedBox(width: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
