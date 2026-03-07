import 'package:flutter/material.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';

/// Card de agendamento na agenda. Usado no dashboard e listas.
class AppointmentCard extends StatelessWidget {
  final String clientName;
  final String statusLabel;
  final Color statusColor;
  final String time;
  final String serviceName;
  final String professionalName;
  final VoidCallback? onTap;

  const AppointmentCard({
    super.key,
    required this.clientName,
    required this.statusLabel,
    required this.statusColor,
    required this.time,
    required this.serviceName,
    required this.professionalName,
    this.onTap,
  });

  factory AppointmentCard.confirmed({
    required String clientName,
    required String time,
    required String serviceName,
    required String professionalName,
    VoidCallback? onTap,
  }) {
    return AppointmentCard(
      clientName: clientName,
      statusLabel: 'Confirmado',
      statusColor: AppTheme.successColor,
      time: time,
      serviceName: serviceName,
      professionalName: professionalName,
      onTap: onTap,
    );
  }

  factory AppointmentCard.pending({
    required String clientName,
    required String time,
    required String serviceName,
    required String professionalName,
    VoidCallback? onTap,
  }) {
    return AppointmentCard(
      clientName: clientName,
      statusLabel: 'Pendente',
      statusColor: AppTheme.warningColor,
      time: time,
      serviceName: serviceName,
      professionalName: professionalName,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  clientName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$time · $serviceName · $professionalName',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: card,
      );
    }

    return card;
  }
}
