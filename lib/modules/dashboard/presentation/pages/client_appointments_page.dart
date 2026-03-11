import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/modules/dashboard/domain/entities/client_appointment_display.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_client_appointments_display_usecase.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/client_appointment_detail_page.dart';
import 'package:fox_link_app/modules/dashboard/presentation/widgets/appointment_section.dart';
import 'package:fox_link_app/modules/dashboard/presentation/widgets/appointments_loading_skeleton.dart';
import 'package:fox_link_app/modules/dashboard/presentation/widgets/empty_appointments_state.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/accept_reschedule_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/cancel_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/presentation/pages/create_appointment_page.dart';

class ClientAppointmentsPage extends StatefulWidget {
  final VoidCallback? onRefreshNeeded;
  final VoidCallback? onNavigateToBook;
  final bool isActive;

  const ClientAppointmentsPage({
    super.key,
    this.onRefreshNeeded,
    this.onNavigateToBook,
    this.isActive = true,
  });

  @override
  State<ClientAppointmentsPage> createState() => _ClientAppointmentsPageState();
}

class _ClientAppointmentsPageState extends State<ClientAppointmentsPage> {
  final _session = GetIt.I<TenantSession>();
  final _getAppointments = GetIt.I<GetClientAppointmentsDisplayUseCase>();
  final _cancelAppointment = GetIt.I<CancelAppointmentUseCase>();
  final _acceptReschedule = GetIt.I<AcceptRescheduleUseCase>();

  late Future<List<ClientAppointmentDisplay>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ClientAppointmentsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _future = _getAppointments(_session.uid!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ClientAppointmentDisplay>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AppointmentsLoadingSkeleton();
        }

        final all = snapshot.data!;
        final now = DateTime.now();

        final upcoming = all
            .where((d) {
              final a = d.appointment;
              if (a.scheduledStart.isBefore(now)) return false;
              return a.status.name != 'cancelled' &&
                  a.status.name != 'rejected' &&
                  a.status.name != 'completed';
            })
            .toList()
          ..sort((a, b) {
            final aReschedule = a.appointment.status.name == 'rescheduleRequested';
            final bReschedule = b.appointment.status.name == 'rescheduleRequested';
            if (aReschedule && !bReschedule) return -1;
            if (!aReschedule && bReschedule) return 1;
            return a.appointment.scheduledStart.compareTo(b.appointment.scheduledStart);
          });

        final pastIds = {for (var e in upcoming) e.appointment.id};
        final past = all
            .where((d) => !pastIds.contains(d.appointment.id))
            .toList()
          ..sort((a, b) => b.appointment.scheduledStart.compareTo(a.appointment.scheduledStart));

        if (all.isEmpty) {
          return EmptyAppointmentsState(onBookTap: widget.onNavigateToBook);
        }

        final reschedulePending = upcoming
            .where((d) => d.appointment.status.name == 'rescheduleRequested')
            .toList();

        return RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (reschedulePending.isNotEmpty) ...[
                  _RescheduleBanner(count: reschedulePending.length),
                  const SizedBox(height: 16),
                ],
                AppointmentSection(
                  title: 'Próximos agendamentos',
                  appointments: upcoming,
                  onAppointmentTap: _openDetail,
                  onCancel: _cancel,
                  onRebook: (d) => () => _rebook(d),
                  onAcceptReschedule: _acceptRescheduleHandler,
                  onRefuseReschedule: _refuseRescheduleHandler,
                  enableSwipeToCancel: true,
                ),
                if (upcoming.isNotEmpty && past.isNotEmpty) const SizedBox(height: 24),
                AppointmentSection(
                  title: 'Agendamentos anteriores',
                  appointments: past,
                  onAppointmentTap: _openDetail,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openDetail(ClientAppointmentDisplay display) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ClientAppointmentDetailPage(display: display),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ).then((_) {
      if (mounted) _load();
      widget.onRefreshNeeded?.call();
    });
  }

  Future<void> _cancel(String appointmentId) async {
    await _cancelAppointment(appointmentId);
    if (mounted) _load();
    widget.onRefreshNeeded?.call();
  }

  Future<void> _acceptRescheduleHandler(ClientAppointmentDisplay display) async {
    final a = display.appointment;
    if (a.status != AppointmentStatus.rescheduleRequested || a.proposedStart == null) return;
    try {
      await _acceptReschedule(a);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reagendamento confirmado!')),
        );
        _load();
      }
      widget.onRefreshNeeded?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _refuseRescheduleHandler(ClientAppointmentDisplay display) async {
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
      await _cancel(display.appointment.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agendamento cancelado. Horário liberado.')),
        );
      }
    }
  }

  void _rebook(ClientAppointmentDisplay display) {
    final a = display.appointment;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => CreateAppointmentPage(
          initialDate: a.scheduledStart,
          initialProfessionalId: a.professionalId,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ).then((_) {
      if (mounted) _load();
      widget.onRefreshNeeded?.call();
    });
  }
}

class _RescheduleBanner extends StatelessWidget {
  final int count;

  const _RescheduleBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning(context).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning(context).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_send, color: AppColors.warning(context), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == 1
                      ? 'Reagendamento solicitado'
                      : '$count reagendamentos solicitados',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'O profissional propôs um novo horário. Toque no agendamento para aceitar ou recusar.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedForeground(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
