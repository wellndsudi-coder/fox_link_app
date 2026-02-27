import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';

import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/scheduling/domain/repositories/scheduling_repository.dart';
import 'package:fox_link_app/modules/availability/domain/repositories/availability_repository.dart';
import 'package:fox_link_app/modules/availability/domain/entities/daily_override.dart';
import 'package:fox_link_app/modules/availability/domain/entities/blocked_date.dart';
import 'package:fox_link_app/modules/availability/presentation/pages/professional_availability_page.dart';

class ProfessionalDashboard extends StatefulWidget {
  const ProfessionalDashboard({super.key});

  @override
  State<ProfessionalDashboard> createState() =>
      _ProfessionalDashboardState();
}

class _ProfessionalDashboardState
    extends State<ProfessionalDashboard> {

  final _repository =
  GetIt.I<SchedulingRepository>();

  final _availabilityRepo =
  GetIt.I<AvailabilityRepository>();

  final _session =
  GetIt.I<TenantSession>();

  DateTime selectedDay = DateTime.now();

  double occupationPercent = 0;
  bool isBlocked = false;
  int totalAppointments = 0;
  double totalRevenue = 0;

  @override
  void initState() {
    super.initState();
    _loadDayData();
  }

  // ==========================================================
  Future<void> _loadDayData() async {

    final blocked =
    await _availabilityRepo.getBlockedDate(
      professionalId: _session.uid!,
      date: selectedDay,
    );

    if (blocked != null) {
      setState(() {
        isBlocked = true;
        occupationPercent = 1;
      });
      return;
    }

    final override =
    await _availabilityRepo.getDailyOverride(
      professionalId: _session.uid!,
      date: selectedDay,
    );

    final availability =
    await _availabilityRepo
        .getWeeklyAvailabilityByWeekday(
      professionalId: _session.uid!,
      weekday: selectedDay.weekday,
    );

    if (availability == null) {
      setState(() {});
      return;
    }

    int start =
        override?.startMinutes ??
            availability.startMinutes;

    int end =
        override?.endMinutes ??
            availability.endMinutes;

    final totalAvailableMinutes =
        end - start;

    final appointments =
    await _repository
        .getApprovedByProfessionalAndDate(
      professionalId: _session.uid!,
      date: selectedDay,
    );

    final usedMinutes =
    appointments.fold<int>(
      0,
          (sum, a) => sum + a.finalDuration,
    );

    totalAppointments =
        appointments.length;

    totalRevenue =
        appointments.fold<double>(
          0,
              (sum, a) => sum + a.finalPrice,
        );

    occupationPercent =
    totalAvailableMinutes == 0
        ? 0
        : usedMinutes /
        totalAvailableMinutes;

    setState(() {
      isBlocked = false;
    });
  }

  // ==========================================================
  Future<void> _openDayEditor() async {

    bool block = false;

    TimeOfDay? startTime;
    TimeOfDay? endTime;

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title:
          const Text("Editar Dia"),
          content:
          StatefulBuilder(
            builder: (context, setLocal) {
              return Column(
                mainAxisSize:
                MainAxisSize.min,
                children: [

                  SwitchListTile(
                    title: const Text(
                        "Bloquear Dia"),
                    value: block,
                    onChanged: (v) {
                      setLocal(() {
                        block = v;
                      });
                    },
                  ),

                  if (!block)
                    Column(
                      children: [

                        ElevatedButton(
                          child: const Text(
                              "Selecionar Início"),
                          onPressed:
                              () async {
                            final picked =
                            await showTimePicker(
                              context:
                              context,
                              initialTime:
                              const TimeOfDay(
                                  hour: 9,
                                  minute: 0),
                            );

                            if (picked !=
                                null) {
                              setLocal(() {
                                startTime =
                                    picked;
                              });
                            }
                          },
                        ),

                        ElevatedButton(
                          child: const Text(
                              "Selecionar Fim"),
                          onPressed:
                              () async {
                            final picked =
                            await showTimePicker(
                              context:
                              context,
                              initialTime:
                              const TimeOfDay(
                                  hour: 18,
                                  minute: 0),
                            );

                            if (picked !=
                                null) {
                              setLocal(() {
                                endTime =
                                    picked;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
          actions: [

            TextButton(
              child:
              const Text("Salvar"),
              onPressed:
                  () async {

                if (block) {

                  await _availabilityRepo
                      .saveBlockedDate(
                    BlockedDate(
                      id:
                      const Uuid()
                          .v4(),
                      professionalId:
                      _session.uid!,
                      date:
                      DateTime(
                        selectedDay
                            .year,
                        selectedDay
                            .month,
                        selectedDay
                            .day,
                      ),
                    ),
                  );

                } else {

                  if (startTime ==
                      null ||
                      endTime ==
                          null) return;

                  await _availabilityRepo
                      .saveDailyOverride(
                    DailyOverride(
                      id:
                      const Uuid()
                          .v4(),
                      professionalId:
                      _session.uid!,
                      date:
                      DateTime(
                        selectedDay
                            .year,
                        selectedDay
                            .month,
                        selectedDay
                            .day,
                      ),
                      startMinutes:
                      startTime!
                          .hour *
                          60 +
                          startTime!
                              .minute,
                      endMinutes:
                      endTime!
                          .hour *
                          60 +
                          endTime!
                              .minute,
                    ),
                  );
                }

                Navigator.pop(context);
                await _loadDayData();
              },
            )
          ],
        );
      },
    );
  }

  // ==========================================================
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
            "Dashboard Profissional"),
        actions: [
          IconButton(
            icon: const Icon(
                Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const ProfessionalAvailabilityPage(),
                ),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [

          TableCalendar(
            firstDay:
            DateTime(2020),
            lastDay:
            DateTime(2100),
            focusedDay:
            selectedDay,
            selectedDayPredicate:
                (day) =>
                isSameDay(
                    day,
                    selectedDay),
            onDaySelected:
                (selected, _) async {
              selectedDay =
                  selected;
              await _loadDayData();
            },
          ),

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed:
            _openDayEditor,
            child: const Text(
                "Editar Dia Selecionado"),
          ),

          const SizedBox(height: 16),

          Text(
            isBlocked
                ? "Dia Bloqueado"
                : "Ocupação: ${(occupationPercent * 100).toStringAsFixed(0)}%",
          ),

          Text(
              "Agendamentos: $totalAppointments"),

          Text(
              "Receita: R\$ ${totalRevenue.toStringAsFixed(2)}"),
        ],
      ),
    );
  }
}