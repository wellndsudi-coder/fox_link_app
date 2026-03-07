import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/get_client_appointments_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/cancel_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/shared/widgets/app_card.dart';
import 'package:fox_link_app/shared/widgets/status_badge.dart';

// 🔥 IMPORTAR FUTURA TELA DE AGENDAMENTO
import 'package:fox_link_app/modules/scheduling/presentation/pages/create_appointment_page.dart';

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() =>
      _ClientDashboardState();
}

class _ClientDashboardState
    extends State<ClientDashboard> {

  final _session = GetIt.I<TenantSession>();
  final _getAppointments =
  GetIt.I<GetClientAppointmentsUseCase>();
  final _cancelAppointment =
  GetIt.I<CancelAppointmentUseCase>();

  late Future<List<Appointment>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _getAppointments(_session.uid!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meus Agendamentos"),
      ),

      // 🔥 BOTÃO NOVO
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateAppointmentPage(),
            ),
          );

          // 🔥 Atualiza ao voltar
          setState(() {
            _load();
          });
        },
        icon: const Icon(Icons.add),
        label: const Text("Agendar"),
      ),

      body: FutureBuilder<List<Appointment>>(
        future: _future,
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
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
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            a.scheduledStart.toString(),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium,
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
      ),
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