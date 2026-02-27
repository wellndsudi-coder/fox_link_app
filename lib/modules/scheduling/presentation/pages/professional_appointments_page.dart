import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';

import '../../domain/entities/appointment.dart';
import '../../domain/repositories/scheduling_repository.dart';
import '../../domain/usecases/approve_appointment_usecase.dart';
import '../../domain/usecases/request_reschedule_usecase.dart';

class ProfessionalAppointmentsPage extends StatefulWidget {
  const ProfessionalAppointmentsPage({super.key});

  @override
  State<ProfessionalAppointmentsPage> createState() =>
      _ProfessionalAppointmentsPageState();
}

class _ProfessionalAppointmentsPageState
    extends State<ProfessionalAppointmentsPage> {

  final _repository =
  GetIt.I<SchedulingRepository>();

  final _approveUseCase =
  GetIt.I<ApproveAppointmentUseCase>();

  final _rescheduleUseCase =
  GetIt.I<RequestRescheduleUseCase>();

  final _session =
  GetIt.I<TenantSession>();

  List<Appointment> pending = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list =
    await _repository.getPendingByProfessional(
      _session.uid!,
    );

    setState(() {
      pending = list;
      loading = false;
    });
  }

  Future<void> _approve(Appointment a) async {
    try {
      await _approveUseCase(a);
      await _load();
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  Future<void> _suggestNewTime(
      Appointment appointment) async {

    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    final newStart = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    final newEnd = newStart.add(
      Duration(minutes: appointment.finalDuration),
    );

    await _rescheduleUseCase(
      appointment: appointment,
      newStart: newStart,
      newEnd: newEnd,
    );

    await _load();
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text("Agendamentos Pendentes"),
      ),
      body: loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : pending.isEmpty
          ? const Center(
        child:
        Text("Nenhum pendente."),
      )
          : ListView.builder(
        itemCount: pending.length,
        itemBuilder: (context, index) {
          final a = pending[index];

          return Card(
            child: ListTile(
              title: Text(
                "${a.scheduledStart}",
              ),
              subtitle: Text(
                "Cliente: ${a.clientId}",
              ),
              trailing: PopupMenuButton<
                  String>(
                onSelected: (value) {
                  if (value ==
                      "approve") {
                    _approve(a);
                  }
                  if (value ==
                      "reschedule") {
                    _suggestNewTime(
                        a);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: "approve",
                    child: Text(
                        "Aprovar"),
                  ),
                  const PopupMenuItem(
                    value:
                    "reschedule",
                    child: Text(
                        "Sugerir novo horário"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}