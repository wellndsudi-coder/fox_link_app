import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/modules/services/domain/entities/service.dart';

/// Summary section for the schedule booking.
/// When [compact] is true, renders a sticky horizontal layout for footer use.
/// Supports base service + addons, total duration/price.
class ScheduleSummary extends StatelessWidget {
  final List<Service> services;
  final String? professionalName;
  final DateTime? date;
  final DateTime? time;
  final bool compact;
  final int? totalDurationMinutes;
  final double? totalPrice;

  const ScheduleSummary({
    super.key,
    this.services = const [],
    this.professionalName,
    this.date,
    this.time,
    this.compact = false,
    this.totalDurationMinutes,
    this.totalPrice,
  });

  bool get hasSelection =>
      services.isNotEmpty ||
      professionalName != null ||
      date != null ||
      time != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!hasSelection) return const SizedBox.shrink();

    if (compact) {
      return _CompactSummary(
        services: services,
        professionalName: professionalName,
        date: date,
        time: time,
        totalDurationMinutes: totalDurationMinutes,
        totalPrice: totalPrice,
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize_rounded, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Resumo',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (services.isNotEmpty)
            _SummaryRow(
              icon: Icons.spa_rounded,
              label: services.length == 1 ? 'Serviço' : 'Serviços',
              value: services.map((s) => s.name.value).join(', '),
            ),
          if (professionalName != null) ...[
            const SizedBox(height: 10),
            _SummaryRow(
              icon: Icons.person_rounded,
              label: 'Profissional',
              value: professionalName!,
            ),
          ],
          if (date != null) ...[
            const SizedBox(height: 10),
            _SummaryRow(
              icon: Icons.calendar_today_rounded,
              label: 'Data',
              value: DateFormat("EEEE, d/MM", 'pt_BR').format(date!),
            ),
          ],
          if (time != null) ...[
            const SizedBox(height: 10),
            _SummaryRow(
              icon: Icons.access_time_rounded,
              label: 'Horário',
              value: DateFormat('HH:mm').format(time!),
            ),
          ],
          if (totalDurationMinutes != null || totalPrice != null) ...[
            const SizedBox(height: 10),
            _SummaryRow(
              icon: Icons.payments_rounded,
              label: 'Total',
              value: [
                if (totalDurationMinutes != null) '$totalDurationMinutes min',
                if (totalPrice != null) 'R\$ ${totalPrice!.toStringAsFixed(2)}',
              ].join(' • '),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactSummary extends StatelessWidget {
  final List<Service> services;
  final String? professionalName;
  final DateTime? date;
  final DateTime? time;
  final int? totalDurationMinutes;
  final double? totalPrice;

  const _CompactSummary({
    this.services = const [],
    this.professionalName,
    this.date,
    this.time,
    this.totalDurationMinutes,
    this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = <String>[];
    if (services.isNotEmpty) {
      parts.add(services.length == 1
          ? services.first.name.value
          : '${services.length} serviços');
    }
    if (professionalName != null) parts.add(professionalName!);
    if (date != null) parts.add(DateFormat('d/MM', 'pt_BR').format(date!));
    if (time != null) parts.add(DateFormat('HH:mm').format(time!));
    if (totalDurationMinutes != null) parts.add('$totalDurationMinutes min');
    if (totalPrice != null) parts.add('R\$ ${totalPrice!.toStringAsFixed(2)}');
    if (parts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: AppColors.border(context)),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.summarize_rounded, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              parts.join(' · '),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.mutedForeground(context)),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.mutedForeground(context),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
