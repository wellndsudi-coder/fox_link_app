// ALTERAÇÃO FOX LINK DASHBOARD — Refatoração UX estilo SaaS (Booksy, Fresha, Trinks)

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/storage/acknowledged_cancellations_storage.dart';
import 'package:fox_link_app/core/utils/date_formatter.dart';
import 'package:fox_link_app/modules/dashboard/domain/entities/client_appointment_display.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/stream_client_appointments_display_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/accept_reschedule_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/approve_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/cancel_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/reject_appointment_usecase.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_top_services_usecase.dart'
    show GetTopServicesUseCase, TopServiceItem;
import 'package:fox_link_app/modules/booking_intelligence/presentation/widgets/first_available_slot_card.dart';
import 'package:fox_link_app/modules/booking_intelligence/presentation/widgets/repeat_appointment_card.dart';
import 'package:fox_link_app/modules/booking_intelligence/presentation/widgets/waiting_list_card.dart';
import 'package:fox_link_app/modules/booking_intelligence/presentation/widgets/client_offered_slots_section.dart';
import 'package:fox_link_app/modules/booking_intelligence/presentation/widgets/favorites_professionals_section.dart';
import 'package:fox_link_app/modules/booking_intelligence/presentation/widgets/client_history_section.dart';
import 'package:fox_link_app/shared/widgets/app_header.dart';
import 'package:fox_link_app/shared/widgets/app_button.dart';

class ClientDashboardPage extends StatefulWidget {
  final void Function(int pageIndex)? onNavigateToPage;
  final void Function({
    required DateTime slot,
    required String professionalId,
    required String professionalName,
    required String serviceId,
  })? onAgendarWithSlot;
  final bool isActive;

  const ClientDashboardPage({
    this.onNavigateToPage,
    this.onAgendarWithSlot,
    this.isActive = true,
  });

  @override
  State<ClientDashboardPage> createState() => _ClientDashboardPageState();
}

class _ClientDashboardPageState extends State<ClientDashboardPage> {
  final _session = GetIt.I<TenantSession>();
  final _streamAppointments = GetIt.I<StreamClientAppointmentsDisplayUseCase>();
  final _ackStorage = GetIt.I<AcknowledgedCancellationsStorage>();
  final _acceptReschedule = GetIt.I<AcceptRescheduleUseCase>();
  final _approveAppointment = GetIt.I<ApproveAppointmentUseCase>();
  final _rejectAppointment = GetIt.I<RejectAppointmentUseCase>();
  final _cancelAppointment = GetIt.I<CancelAppointmentUseCase>();

  late Future<Set<String>> _futureAcknowledged;

  @override
  void initState() {
    super.initState();
    _loadAcknowledged();
  }

  @override
  void didUpdateWidget(covariant ClientDashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _loadAcknowledged();
    }
  }

  void _loadAcknowledged() {
    final uid = _session.uid ?? '';
    _futureAcknowledged = _ackStorage.getAcknowledged(uid);
  }

  String _getUserName() {
    return _session.email?.split('@').first ?? 'Cliente';
  }

  @override
  Widget build(BuildContext context) {
    final uid = _session.uid ?? '';
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          _loadAcknowledged();
          setState(() {});
        },
        child: FutureBuilder<Set<String>>(
          future: _futureAcknowledged,
          builder: (context, ackSnapshot) {
            final acknowledged = ackSnapshot.data ?? {};
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppHeader(
                    title: 'Olá, ${_getUserName()} 👋',
                    subtitle: 'Pronto para seu próximo horário?',
                    isGreeting: true,
                  ),
                  const SizedBox(height: 16),
                  _DashboardAppointmentCard(
                    stream: _session.uid != null
                        ? _streamAppointments(_session.uid!)
                        : Stream.value(<ClientAppointmentDisplay>[]),
                    acknowledgedIds: acknowledged,
                    onAcceptAppointment: (a) async {
                      try {
                        await _approveAppointment(a);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Agendamento confirmado!')),
                          );
                          setState(() {});
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      }
                    },
                    onRejectAppointment: (display) async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Recusar horário?'),
                          content: const Text('O agendamento proposto será recusado e o horário ficará disponível.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text('Sim, recusar', style: TextStyle(color: AppColors.error(ctx))),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        try {
                          await _rejectAppointment(display.appointment);
                          if (mounted) {
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Horário recusado.')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      }
                    },
                    onAcceptReschedule: (a) async {
                      try {
                        await _acceptReschedule(a);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reagendamento confirmado!')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      }
                    },
                    onRefuseReschedule: (display) async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Recusar reagendamento?'),
                          content: const Text('O agendamento será cancelado.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text('Sim', style: TextStyle(color: AppColors.error(ctx))),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _cancelAppointment(display.appointment.id);
                        await _ackStorage.acknowledge(uid, display.appointment.id);
                        if (mounted) {
                          _loadAcknowledged();
                          setState(() {});
                        }
                      }
                    },
                    onAcknowledgeCancelled: (appointmentId) async {
                      await _ackStorage.acknowledge(uid, appointmentId);
                      if (mounted) {
                        _loadAcknowledged();
                        setState(() {});
                      }
                    },
                    onSeeDetails: () => widget.onNavigateToPage?.call(2),
                    onAgendar: () => widget.onNavigateToPage?.call(1),
                    onCancelAppointment: (display) async {
                      final statusLabel = switch (display.appointment.status) {
                        AppointmentStatus.approved => 'Confirmado',
                        AppointmentStatus.pending => 'Pendente',
                        _ => display.appointment.status.name,
                      };
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Cancelar agendamento?'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status: $statusLabel',
                                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${display.serviceName} • ${AppDateFormatter.friendlyDateAndTime(display.appointment.scheduledStart)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.mutedForeground(ctx),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Tem certeza que deseja cancelar este agendamento? O horário ficará disponível.',
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Não'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(
                                'Sim, cancelar',
                                style: TextStyle(color: AppColors.error(ctx)),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        try {
                          await _cancelAppointment(display.appointment.id);
                          await _ackStorage.acknowledge(uid, display.appointment.id);
                          if (mounted) {
                            _loadAcknowledged();
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Agendamento cancelado. Horário liberado.')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      }
                    },
                  ),
                      const SizedBox(height: 16),
                      AppButton(
                        text: '+ Agendar horário',
                        onPressed: () => widget.onNavigateToPage?.call(1),
                      ),
                  const SizedBox(height: 16),
                  // FOX LINK BOOKING INTELLIGENCE: Primeiro horário disponível
                      FirstAvailableSlotCard(
                        onNavigateToPage: widget.onNavigateToPage,
                        onAgendarWithSlot: widget.onAgendarWithSlot,
                      ),
                      const SizedBox(height: 16),
                      WaitingListCard(
                        onNavigateToPage: widget.onNavigateToPage,
                      ),
                      const SizedBox(height: 16),
                      RepeatAppointmentCard(
                    onNavigateToPage: widget.onNavigateToPage,
                  ),
                      _PopularServicesSection(
                    onNavigateToPage: widget.onNavigateToPage,
                  ),
                      const SizedBox(height: 16),
                      FavoritesProfessionalsSection(
                        onNavigateToPage: widget.onNavigateToPage,
                      ),
                      ClientOfferedSlotsSection(
                        onNavigateToPage: widget.onNavigateToPage,
                      ),
                      const SizedBox(height: 16),
                      ClientHistorySection(
                        onNavigateToPage: widget.onNavigateToPage,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
  }
}

enum DashboardCardType { rescheduleRequested, pendingConfirmation, cancelled, nextAppointment, empty }

class _DashboardAppointmentCard extends StatelessWidget {
  final Stream<List<ClientAppointmentDisplay>> stream;
  final Set<String> acknowledgedIds;
  final void Function(Appointment a) onAcceptAppointment;
  final void Function(ClientAppointmentDisplay display) onRejectAppointment;
  final void Function(Appointment a) onAcceptReschedule;
  final void Function(ClientAppointmentDisplay display) onRefuseReschedule;
  final void Function(String appointmentId) onAcknowledgeCancelled;
  final VoidCallback? onSeeDetails;
  final VoidCallback? onAgendar;
  final void Function(ClientAppointmentDisplay display)? onCancelAppointment;

  const _DashboardAppointmentCard({
    required this.stream,
    required this.acknowledgedIds,
    required this.onAcceptAppointment,
    required this.onRejectAppointment,
    required this.onAcceptReschedule,
    required this.onRefuseReschedule,
    required this.onAcknowledgeCancelled,
    this.onSeeDetails,
    this.onAgendar,
    this.onCancelAppointment,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ClientAppointmentDisplay>>(
      stream: stream,
      builder: (context, snapshot) {
        final all = snapshot.data ?? [];
        final now = DateTime.now();

        final rescheduleRequested = all
            .where((d) =>
                d.appointment.scheduledStart.isAfter(now) &&
                d.appointment.status == AppointmentStatus.rescheduleRequested)
            .toList()
          ..sort((a, b) => a.appointment.scheduledStart.compareTo(b.appointment.scheduledStart));
        final pendingConfirmation = all
            .where((d) =>
                d.appointment.scheduledStart.isAfter(now) &&
                d.appointment.status == AppointmentStatus.pending)
            .toList()
          ..sort((a, b) => a.appointment.scheduledStart.compareTo(b.appointment.scheduledStart));
        final recentCancelled = all
            .where((d) =>
                d.appointment.status == AppointmentStatus.cancelled &&
                !acknowledgedIds.contains(d.appointment.id) &&
                d.appointment.cancelledAt != null &&
                d.appointment.cancelledAt!.isAfter(now.subtract(const Duration(days: 7))))
            .toList()
          ..sort((a, b) => (b.appointment.cancelledAt ?? DateTime.now())
              .compareTo(a.appointment.cancelledAt ?? DateTime.now()));
        final upcomingApproved = all
            .where((d) =>
                d.appointment.scheduledStart.isAfter(now) &&
                d.appointment.status == AppointmentStatus.approved)
            .toList()
          ..sort((a, b) => a.appointment.scheduledStart.compareTo(b.appointment.scheduledStart));
        final nextAppointment = upcomingApproved.isNotEmpty ? upcomingApproved.first : null;

        DashboardCardType cardType;
        ClientAppointmentDisplay? cardDisplay;
        if (rescheduleRequested.isNotEmpty) {
          cardType = DashboardCardType.rescheduleRequested;
          cardDisplay = rescheduleRequested.first;
        } else if (pendingConfirmation.isNotEmpty) {
          cardType = DashboardCardType.pendingConfirmation;
          cardDisplay = pendingConfirmation.first;
        } else if (recentCancelled.isNotEmpty) {
          cardType = DashboardCardType.cancelled;
          cardDisplay = recentCancelled.first;
        } else if (nextAppointment != null) {
          cardType = DashboardCardType.nextAppointment;
          cardDisplay = nextAppointment;
        } else {
          cardType = DashboardCardType.empty;
        }

        if (snapshot.connectionState == ConnectionState.waiting && all.isEmpty) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (cardType == DashboardCardType.rescheduleRequested && cardDisplay != null) {
          final d = cardDisplay;
          return _RescheduleRequestedCard(
            display: d,
            onAccept: () => onAcceptReschedule(d.appointment),
            onRefuse: () => onRefuseReschedule(d),
            onSeeDetails: onSeeDetails,
          );
        }
        if (cardType == DashboardCardType.pendingConfirmation && cardDisplay != null) {
          final d = cardDisplay;
          return _PendingConfirmationCard(
            display: d,
            onAccept: () => onAcceptAppointment(d.appointment),
            onReject: () => onRejectAppointment(d),
            onSeeDetails: onSeeDetails,
          );
        }
        if (cardType == DashboardCardType.cancelled && cardDisplay != null) {
          final d = cardDisplay;
          return _CancelledNoticeCard(
            display: d,
            appointmentId: d.appointment.id,
            onOk: onAcknowledgeCancelled,
          );
        }
        if (cardType == DashboardCardType.nextAppointment && cardDisplay != null) {
          final d = cardDisplay;
          return _NextAppointmentCard(
            display: d,
            onTap: onSeeDetails,
            onReagendar: onSeeDetails,
            onCancelar: onCancelAppointment != null
                ? () => onCancelAppointment!(d)
                : null,
          );
        }
        return _EmptyNextAppointmentCard(onTap: onAgendar);
      },
    );
  }
}

class _RescheduleRequestedCard extends StatelessWidget {
  final ClientAppointmentDisplay display;
  final VoidCallback onAccept;
  final VoidCallback onRefuse;
  final VoidCallback? onSeeDetails;

  const _RescheduleRequestedCard({
    required this.display,
    required this.onAccept,
    required this.onRefuse,
    this.onSeeDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = display.appointment;
    final warning = AppColors.warning(context);

    return Container(
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: warning.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule_send, color: warning),
                const SizedBox(width: 8),
                Text(
                  'Reagendamento solicitado',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              display.serviceName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Seu horário de ${AppDateFormatter.friendlyDateAndTime(a.scheduledStart)} foi alterado para ${a.proposedStart != null ? AppDateFormatter.friendlyDateAndTime(a.proposedStart!) : "novo horário"}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedForeground(context),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton(
                  onPressed: onAccept,
                  child: const Text('Aceitar'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onRefuse,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error(context),
                  ),
                  child: const Text('Recusar'),
                ),
                if (onSeeDetails != null) ...[
                  const Spacer(),
                  TextButton(
                    onPressed: onSeeDetails,
                    child: const Text('Ver detalhes'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingConfirmationCard extends StatelessWidget {
  final ClientAppointmentDisplay display;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback? onSeeDetails;

  const _PendingConfirmationCard({
    required this.display,
    required this.onAccept,
    required this.onReject,
    this.onSeeDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = display.appointment;
    final primary = theme.colorScheme.primary;
    final wasProposedByProfessional = a.initiatedBy == 'professional';

    return Container(
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  wasProposedByProfessional ? Icons.person_add : Icons.schedule,
                  color: primary,
                ),
                const SizedBox(width: 8),
                Text(
                  wasProposedByProfessional
                      ? 'Horário proposto por ${display.professionalName}'
                      : 'Aguardando confirmação do profissional',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              display.serviceName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat("EEEE, d 'de' MMMM • HH:mm", 'pt_BR').format(a.scheduledStart),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedForeground(context),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (wasProposedByProfessional) ...[
                  FilledButton(
                    onPressed: onAccept,
                    child: const Text('Aceitar'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error(context),
                    ),
                    child: const Text('Recusar'),
                  ),
                ],
                if (onSeeDetails != null) ...[
                  const Spacer(),
                  TextButton(
                    onPressed: onSeeDetails,
                    child: const Text('Ver detalhes'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CancelledNoticeCard extends StatelessWidget {
  final ClientAppointmentDisplay display;
  final String appointmentId;
  final void Function(String appointmentId) onOk;

  const _CancelledNoticeCard({
    required this.display,
    required this.appointmentId,
    required this.onOk,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = display.appointment;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.mutedForeground(context).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_busy, color: AppColors.mutedForeground(context)),
                const SizedBox(width: 8),
                Text(
                  'Agendamento cancelado',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedForeground(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${display.serviceName} • ${AppDateFormatter.friendlyDateAndTime(a.scheduledStart)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedForeground(context),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => onOk(appointmentId),
                child: const Text('Ok'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextAppointmentCard extends StatelessWidget {
  final ClientAppointmentDisplay display;
  final VoidCallback? onTap;
  final VoidCallback? onReagendar;
  final VoidCallback? onCancelar;

  const _NextAppointmentCard({
    required this.display,
    this.onTap,
    this.onReagendar,
    this.onCancelar,
  });

  String _statusLabel(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.approved:
        return 'Confirmado';
      case AppointmentStatus.pending:
        return 'Pendente';
      default:
        return s.toString().split('.').last;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: primary),
                    const SizedBox(width: 8),
                    Text(
                      'Próximo agendamento',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel(display.appointment.status),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  DateFormat("EEEE, d 'de' MMMM", 'pt_BR')
                      .format(display.appointment.scheduledStart),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm', 'pt_BR').format(display.appointment.scheduledStart),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.mutedForeground(context),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton(
                      onPressed: onReagendar,
                      child: const Text('Reagendar'),
                    ),
                    TextButton(
                      onPressed: onCancelar,
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ALTERAÇÃO FOX LINK DASHBOARD: Empty state do card principal
class _EmptyNextAppointmentCard extends StatelessWidget {
  final VoidCallback? onTap;

  const _EmptyNextAppointmentCard({this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  color: theme.colorScheme.primary,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Próximo agendamento',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nenhum agendamento em breve',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedForeground(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ALTERAÇÃO FOX LINK DASHBOARD: Seção Serviços populares
class _PopularServicesSection extends StatelessWidget {
  final void Function(int pageIndex)? onNavigateToPage;

  const _PopularServicesSection({this.onNavigateToPage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<TopServiceItem>>(
      future: GetIt.I<GetTopServicesUseCase>()(limit: 6),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Serviços populares',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final name = item.serviceName;
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < items.length - 1 ? 12 : 0,
                    ),
                    child: _ServiceChip(
                      label: name,
                      onTap: () => onNavigateToPage?.call(1),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _ServiceChip({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 90,
          padding: const EdgeInsets.all(12),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatefulWidget {
  @override
  State<_DashboardSkeleton> createState() => _DashboardSkeletonState();
}

class _DashboardSkeletonState extends State<_DashboardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _shimmerBox(double width, double height) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade300.withValues(
              alpha: _animation.value,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _shimmerBox(180, 28),
          const SizedBox(height: 8),
          _shimmerBox(220, 18),
          const SizedBox(height: 16),
          _shimmerBox(double.infinity, 160),
          const SizedBox(height: 16),
          _shimmerBox(double.infinity, 52),
          const SizedBox(height: 16),
          _shimmerBox(120, 20),
          const SizedBox(height: 8),
          _shimmerBox(double.infinity, 100),
          const SizedBox(height: 16),
          _shimmerBox(double.infinity, 80),
          const SizedBox(height: 16),
          _shimmerBox(double.infinity, 100),
        ],
      ),
    );
  }
}
