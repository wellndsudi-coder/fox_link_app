import 'package:flutter/material.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';

/// Card de metrica do dashboard. Usado no layout estilo Lovable.
class DashboardCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final String? trend;

  const DashboardCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedForeground,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
              ),
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSm),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (subtitle != null || trend != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                  ),
                if (subtitle != null && trend != null)
                  Text(
                    ' · ',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (trend != null)
                  Text(
                    trend!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
