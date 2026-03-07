import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/get_client_appointments_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/cancel_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/shared/widgets/app_card.dart';
import 'package:fox_link_app/shared/widgets/status_badge.dart';

class ClientAppointmentsPage extends StatefulWidget {
  final VoidCallback? onRefreshNeeded;
  final bool isActive;

  const ClientAppointmentsPage({
    super.key,
    this.onRefreshNeeded,
    this.isActive = true,
  });

  @override
  State<ClientAppointmentsPage> createState() => _ClientAppointmentsPageState();
}

class _ClientAppointmentsPageState extends State<ClientAppointmentsPage> {
  final _session = GetIt.I<TenantSession>();
  final _getAppointments = GetIt.I<GetClientAppointmentsUseCase>();
  final _cancelAppointment = GetIt.I<CancelAppointmentUseCase>();

  late Future<List<Appointment>> _future;

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

  void _load() {
    _future = _getAppointments(_session.uid!);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Appointment>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final appointments = snapshot.data!;

        if (appointments.isEmpty) {
          return const Center(
            child: Text("Nenhum agendamento encontrado."),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (_, index) {
            final a = appointments[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          a.scheduledStart.toString(),
                          style:
                              Theme.of(context).textTheme.headlineMedium,
                        ),
                        StatusBadge(
                          status: _mapStatus(a.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (a.status == AppointmentStatus.pending ||
                        a.status == AppointmentStatus.approved)
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () async {
                            await _cancelAppointment(a.id);
                            setState(() {
                              _load();
                            });
                            widget.onRefreshNeeded?.call();
                          },
                          child: const Text("Cancelar"),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
      case AppointmentStatus.noShow:
        return AppStatus.pending;
    }
  }
}
