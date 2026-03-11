import 'package:flutter/material.dart';

import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/utils/appointment_status_label.dart';
import 'package:fox_link_app/core/utils/date_formatter.dart';
import 'package:fox_link_app/modules/dashboard/domain/entities/client_appointment_display.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/shared/widgets/status_badge.dart';

class ClientAppointmentCard extends StatelessWidget {
  final ClientAppointmentDisplay display;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onRebook;
  final VoidCallback? onAcceptReschedule;
  final VoidCallback? onRefuseReschedule;

  const ClientAppointmentCard({
    super.key,
    required this.display,
    this.onTap,
    this.onCancel,
    this.onRebook,
    this.onAcceptReschedule,
    this.onRefuseReschedule,
  });

  bool get _isUpcoming {
    final a = display.appointment;
    if (a.scheduledStart.isBefore(DateTime.now())) return false;
    return a.status == AppointmentStatus.pending ||
        a.status == AppointmentStatus.approved ||
        a.status == AppointmentStatus.rescheduleRequested;
  }

  bool get _isStartingSoon {
    final now = DateTime.now();
    final start = display.appointment.scheduledStart;
    return start.isAfter(now) && start.difference(now).inMinutes <= 30;
  }

  AppStatus _mapStatus(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return AppStatus.pending;
      case AppointmentStatus.approved:
        return AppStatus.approved;
      case AppointmentStatus.rejected:
        return AppStatus.rejected;
      case AppointmentStatus.cancelled:
        return AppStatus.cancelled;
      case AppointmentStatus.completed:
        return AppStatus.completed;
      case AppointmentStatus.rescheduleRequested:
        return AppStatus.rescheduleRequested;
      case AppointmentStatus.noShow:
      case AppointmentStatus.waitingList:
        return AppStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = display.appointment;

    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            display.serviceName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 14, color: AppColors.mutedForeground(context)),
              const SizedBox(width: 6),
              Text(
                display.professionalName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedForeground(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.mutedForeground(context)),
                  const SizedBox(width: 6),
                  Text(
                    AppDateFormatter.friendlyDate(a.scheduledStart),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedForeground(context),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: AppColors.mutedForeground(context)),
                  const SizedBox(width: 6),
                  Text(
                    '${getAppointmentStatusLabel(a)} • ${AppDateFormatter.friendlyTime(a.scheduledStart)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedForeground(context),
                    ),
                  ),
                ],
              ),
              Text(
                AppDateFormatter.friendlyDuration(a.finalDuration),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedForeground(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_isStartingSoon && _isUpcoming)
                StatusBadge(status: _mapStatus(a.status), startingSoon: true)
              else
                StatusBadge(status: _mapStatus(a.status)),
            ],
          ),
          if (_isUpcoming) ...[
            if (a.status == AppointmentStatus.rescheduleRequested &&
                (a.proposedStart != null || onTap != null)) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.warning(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule_send, size: 16, color: AppColors.warning(context)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            a.proposedStart != null
                                ? 'Seu horário de ${AppDateFormatter.friendlyDateAndTime(a.scheduledStart)} foi alterado para ${AppDateFormatter.friendlyDateAndTime(a.proposedStart!)}'
                                : 'Toque para aceitar ou recusar o novo horário',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.warning(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (onAcceptReschedule != null && onRefuseReschedule != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton(
                            onPressed: onAcceptReschedule,
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: const Text('Aceitar'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: onRefuseReschedule,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error(context),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: const Text('Recusar'),
                          ),
                        ],
                      ),
                    ] else if (onTap != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: onTap,
                        child: Text('Responder', style: TextStyle(color: AppColors.warning(context), fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (a.status != AppointmentStatus.rescheduleRequested) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (onRebook != null)
                    TextButton(
                      onPressed: onRebook,
                      child: Text('Reagendar', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                    ),
                  if (onRebook != null) const SizedBox(width: 8),
                  if (onCancel != null)
                    TextButton(
                      onPressed: onCancel,
                      child: Text('Cancelar', style: TextStyle(color: AppColors.error(context), fontWeight: FontWeight.w500)),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      );
    }
    return card;
  }
}
