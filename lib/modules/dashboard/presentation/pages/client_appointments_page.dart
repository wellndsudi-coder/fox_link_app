import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/dashboard/domain/entities/client_appointment_display.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_client_appointments_display_usecase.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/client_appointment_detail_page.dart';
import 'package:fox_link_app/modules/dashboard/presentation/widgets/appointment_section.dart';
import 'package:fox_link_app/modules/dashboard/presentation/widgets/appointments_loading_skeleton.dart';
import 'package:fox_link_app/modules/dashboard/presentation/widgets/empty_appointments_state.dart';
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
          ..sort((a, b) => a.appointment.scheduledStart.compareTo(b.appointment.scheduledStart));

        final pastIds = {for (var e in upcoming) e.appointment.id};
        final past = all
            .where((d) => !pastIds.contains(d.appointment.id))
            .toList()
          ..sort((a, b) => b.appointment.scheduledStart.compareTo(a.appointment.scheduledStart));

        if (all.isEmpty) {
          return EmptyAppointmentsState(onBookTap: widget.onNavigateToBook);
        }

        return RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppointmentSection(
                  title: 'Próximos agendamentos',
                  appointments: upcoming,
                  onAppointmentTap: _openDetail,
                  onCancel: _cancel,
                  onRebook: (d) => () => _rebook(d),
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
