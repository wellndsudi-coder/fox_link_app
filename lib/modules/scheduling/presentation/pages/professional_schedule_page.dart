import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/modules/scheduling/domain/repositories/scheduling_repository.dart';

class ProfessionalSchedulePage extends StatefulWidget {
  const ProfessionalSchedulePage({super.key});

  @override
  State<ProfessionalSchedulePage> createState() =>
      _ProfessionalSchedulePageState();
}

class _ProfessionalSchedulePageState
    extends State<ProfessionalSchedulePage>
    with SingleTickerProviderStateMixin {

  final _repository =
  GetIt.I<SchedulingRepository>();

  final _session =
  GetIt.I<TenantSession>();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Minha Agenda"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Hoje"),
            Tab(text: "Pendentes"),
            Tab(text: "Próximos"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildToday(),
          _buildPending(),
          _buildUpcoming(),
        ],
      ),
    );
  }

  // ==========================================================
  // 🔹 HOJE
  // ==========================================================
  Widget _buildToday() {
    return FutureBuilder<List<Appointment>>(
      future: _repository.getApprovedByProfessionalAndDate(
        professionalId: _session.uid!,
        date: DateTime.now(),
      ),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator());
        }

        final appointments = snapshot.data!;

        if (appointments.isEmpty) {
          return const Center(
            child: Text("Nenhum agendamento hoje"),
          );
        }

        return ListView.builder(
          itemCount: appointments.length,
          itemBuilder: (_, index) {
            return _appointmentCard(
                appointments[index]);
          },
        );
      },
    );
  }

  // ==========================================================
  // 🔹 PENDENTES
  // ==========================================================
  Widget _buildPending() {
    return FutureBuilder<List<Appointment>>(
      future: _repository.getPendingByProfessional(
        _session.uid!,
      ),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator());
        }

        final appointments = snapshot.data!;

        if (appointments.isEmpty) {
          return const Center(
            child: Text("Sem solicitações pendentes"),
          );
        }

        return ListView.builder(
          itemCount: appointments.length,
          itemBuilder: (_, index) {
            return _pendingCard(
                appointments[index]);
          },
        );
      },
    );
  }

  // ==========================================================
  // 🔹 PRÓXIMOS
  // ==========================================================
  Widget _buildUpcoming() {
    return const Center(
      child: Text("Próximos agendamentos"),
    );
  }

  // ==========================================================
  // 🔹 CARD NORMAL
  // ==========================================================
  Widget _appointmentCard(Appointment a) {
    return Card(
      margin:
      const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8),
      child: ListTile(
        title: Text(
            "Cliente: ${a.clientId}"),
        subtitle: Text(
            "${a.scheduledStart.hour.toString().padLeft(2, '0')}:${a.scheduledStart.minute.toString().padLeft(2, '0')}"),
        trailing: Text(
          a.status.name,
          style: const TextStyle(
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ==========================================================
  // 🔹 CARD PENDENTE COM AÇÕES
  // ==========================================================
  Widget _pendingCard(Appointment a) {
    return Card(
      margin:
      const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(
                "Cliente: ${a.clientId}"),
            subtitle: Text(
                "${a.scheduledStart.day}/${a.scheduledStart.month} - ${a.scheduledStart.hour}:${a.scheduledStart.minute}"),
          ),
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () async {
                  await _repository.updateStatus(
                    a.id,
                    AppointmentStatus.approved,
                  );
                  setState(() {});
                },
                child: const Text("Aprovar"),
              ),
              TextButton(
                onPressed: () async {
                  await _repository.updateStatus(
                    a.id,
                    AppointmentStatus.rejected,
                  );
                  setState(() {});
                },
                child: const Text("Recusar"),
              ),
            ],
          )
        ],
      ),
    );
  }
}