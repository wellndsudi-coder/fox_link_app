import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/core/utils/date_formatter.dart';
import 'package:fox_link_app/modules/dashboard/domain/entities/client_appointment_display.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/cancel_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/accept_reschedule_usecase.dart';
import 'package:fox_link_app/modules/scheduling/presentation/pages/create_appointment_page.dart';
import 'package:fox_link_app/shared/widgets/app_button.dart';
import 'package:fox_link_app/shared/widgets/status_badge.dart';

class ClientAppointmentDetailPage extends StatelessWidget {
  final ClientAppointmentDisplay display;

  const ClientAppointmentDetailPage({
    super.key,
    required this.display,
  });

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
      case AppointmentStatus.noShow:
      case AppointmentStatus.waitingList:
        return AppStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = display.appointment;
    final isUpcoming = a.scheduledStart.isAfter(DateTime.now()) &&
        a.status != AppointmentStatus.cancelled &&
        a.status != AppointmentStatus.completed &&
        a.status != AppointmentStatus.rejected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do agendamento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DetailCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    display.serviceName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 18, color: AppColors.mutedForeground(context)),
                      const SizedBox(width: 8),
                      Text(
                        display.professionalName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.mutedForeground(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Data',
                    value: AppDateFormatter.friendlyDate(a.scheduledStart),
                  ),
                  const SizedBox(height: 10),
                  _DetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Horário',
                    value: AppDateFormatter.friendlyTime(a.scheduledStart),
                  ),
                  const SizedBox(height: 10),
                  _DetailRow(
                    icon: Icons.timer_outlined,
                    label: 'Duração',
                    value: AppDateFormatter.friendlyDuration(a.finalDuration),
                  ),
                  const SizedBox(height: 16),
                  StatusBadge(status: _mapStatus(a.status)),
                  if (a.status == AppointmentStatus.rescheduleRequested &&
                      a.proposedStart != null &&
                      a.proposedEnd != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Novo horário proposto:',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.mutedForeground(context),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${AppDateFormatter.friendlyDate(a.proposedStart!)} às ${AppDateFormatter.friendlyTime(a.proposedStart!)}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (a.status == AppointmentStatus.rescheduleRequested) ...[
              const SizedBox(height: 24),
              AppButton(
                text: 'Aceitar reagendamento',
                onPressed: () async {
                  try {
                    await GetIt.I<AcceptRescheduleUseCase>()(a);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reagendamento confirmado!')),
                      );
                      Navigator.of(context).pop(true);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'Recusar',
                variant: AppButtonVariant.outline,
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Recusar reagendamento?'),
                      content: const Text(
                        'O agendamento será cancelado e o horário ficará livre.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Voltar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text('Sim, recusar', style: TextStyle(color: AppColors.error(ctx))),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await GetIt.I<CancelAppointmentUseCase>()(a.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Agendamento cancelado. Horário liberado.')),
                      );
                      Navigator.of(context).pop(true);
                    }
                  }
                },
              ),
            ] else if (isUpcoming) ...[
              const SizedBox(height: 24),
              AppButton(
                text: 'Reagendar',
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreateAppointmentPage(
                        initialDate: a.scheduledStart,
                        initialProfessionalId: a.professionalId,
                      ),
                    ),
                  ).then((_) => Navigator.of(context).pop());
                },
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'Cancelar agendamento',
                variant: AppButtonVariant.outline,
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Cancelar agendamento?'),
                      content: const Text(
                        'Tem certeza que deseja cancelar este agendamento?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Não'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text('Sim', style: TextStyle(color: AppColors.error(ctx))),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await GetIt.I<CancelAppointmentUseCase>()(a.id);
                    navigator.pop(true);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final Widget child;

  const _DetailCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
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
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.mutedForeground(context),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
