import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_weekly_timegrid_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/approve_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/cancel_appointment_usecase.dart';
import 'package:fox_link_app/modules/availability/domain/usecases/get_professional_availability.dart';
import 'package:fox_link_app/modules/availability/domain/entities/availability.dart';

class ProfessionalAgendaPage extends StatefulWidget {
  final bool isActive;

  const ProfessionalAgendaPage({
    super.key,
    required this.isActive,
  });

  @override
  State<ProfessionalAgendaPage> createState() =>
      _ProfessionalAgendaPageState();
}

class _ProfessionalAgendaPageState
    extends State<ProfessionalAgendaPage> {

  final _session = GetIt.I<TenantSession>();
  final _timeGridUseCase =
  GetIt.I<GetWeeklyTimeGridUseCase>();
  final _availabilityUseCase =
  GetIt.I<GetProfessionalAvailability>();

  final _approveUseCase =
  GetIt.I<ApproveAppointmentUseCase>();
  final _cancelUseCase =
  GetIt.I<CancelAppointmentUseCase>();

  DateTime selectedDate = DateTime.now();

  @override
  void didUpdateWidget(
      covariant ProfessionalAgendaPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive && !oldWidget.isActive) {
      setState(() {});
    }
  }

  Future<Map<String, dynamic>> _loadAgendaData() async {

    final professionalId =
        _session.professionalId;

    if (professionalId == null) {
      return {
        'availability': null,
        'blocks': [],
      };
    }

    final availabilityList =
    await _availabilityUseCase(professionalId);

    Availability? todayAvailability;

    for (final a in availabilityList) {
      if (a.weekday == selectedDate.weekday) {
        todayAvailability = a;
        break;
      }
    }

    final blocks = await _timeGridUseCase(
      professionalId: professionalId,
      referenceDate: selectedDate,
    );

    return {
      'availability': todayAvailability,
      'blocks': blocks
          .where((b) =>
      b.weekday == selectedDate.weekday)
          .toList(),
    };
  }

  void _goToToday() {
    setState(() {
      selectedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {

    final weekStart = selectedDate
        .subtract(Duration(days: selectedDate.weekday - 1));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text("Minha Agenda"),
        actions: [
          TextButton(
            onPressed: _goToToday,
            child: const Text("Hoje"),
          )
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [

            /// HEADER SEMANA
            SliverToBoxAdapter(
              child: Container(
                padding:
                const EdgeInsets.symmetric(vertical: 8),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
                  children: List.generate(7, (index) {
                    final day =
                    weekStart.add(Duration(days: index));

                    final isSelected =
                    DateUtils.isSameDay(
                        day, selectedDate);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDate = day;
                        });
                      },
                      child: Column(
                        children: [
                          Text(
                            DateFormat.E().format(day),
                            style: const TextStyle(
                                fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding:
                            const EdgeInsets.all(8),
                            decoration:
                            BoxDecoration(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              day.day.toString(),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),

            /// CORPO
            SliverFillRemaining(
              child: FutureBuilder(
                future: _loadAgendaData(),
                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final data = snapshot.data!;
                  final Availability? availability =
                  data['availability'];
                  final List blocks =
                  data['blocks'];

                  if (availability == null ||
                      !availability.isActive ||
                      availability.shifts.isEmpty) {
                    return const Center(
                      child: Text(
                        "Você não atende neste dia.",
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  final shifts =
                      availability.shifts;
                  final breaks =
                      availability.breakTimes;

                  int minStart = shifts
                      .map((s) => s.startMinutes)
                      .reduce((a, b) =>
                  a < b ? a : b);

                  int maxEnd = shifts
                      .map((s) => s.endMinutes)
                      .reduce((a, b) =>
                  a > b ? a : b);

                  final totalMinutes =
                      maxEnd - minStart;

                  const double hourHeight = 80;

                  final totalHeight =
                      (totalMinutes / 60) *
                          hourHeight;

                  return SingleChildScrollView(
                    child: SizedBox(
                      height: totalHeight,
                      child: Row(
                        children: [

                          /// COLUNA HORÁRIOS
                          SizedBox(
                            width: 60,
                            child: Column(
                              children:
                              List.generate(
                                (totalMinutes /
                                    60)
                                    .ceil(),
                                    (index) {
                                  final minutes =
                                      minStart +
                                          (index *
                                              60);

                                  final hour =
                                      minutes ~/ 60;
                                  final minute =
                                      minutes % 60;

                                  return Container(
                                    height:
                                    hourHeight,
                                    alignment:
                                    Alignment
                                        .topCenter,
                                    child: Text(
                                      "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}",
                                      style:
                                      const TextStyle(
                                        fontSize:
                                        12,
                                        color:
                                        Colors
                                            .grey,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          /// ÁREA AGENDA
                          Expanded(
                            child: Stack(
                              children: [

                                /// GRID
                                Column(
                                  children:
                                  List.generate(
                                    (totalMinutes /
                                        60)
                                        .ceil(),
                                        (_) =>
                                        Container(
                                          height:
                                          hourHeight,
                                          decoration:
                                          const BoxDecoration(
                                            border:
                                            Border(
                                              bottom:
                                              BorderSide(
                                                color:
                                                Color(0xFFE2E8F0),
                                              ),
                                            ),
                                          ),
                                        ),
                                  ),
                                ),

                                /// BREAKS
                                ...breaks.map((b) {

                                  final top =
                                      ((b.startMinutes -
                                          minStart) /
                                          totalMinutes) *
                                          totalHeight;

                                  final height =
                                      ((b.endMinutes -
                                          b.startMinutes) /
                                          totalMinutes) *
                                          totalHeight;

                                  return Positioned(
                                    top: top,
                                    left: 0,
                                    right: 0,
                                    height: height,
                                    child:
                                    Container(
                                      color: Colors
                                          .grey
                                          .withOpacity(
                                          0.2),
                                    ),
                                  );
                                }),

                                /// AGENDAMENTOS
                                ...blocks.map(
                                      (block) {

                                    final top =
                                        ((block.startMinutes -
                                            minStart) /
                                            totalMinutes) *
                                            totalHeight;

                                    final height =
                                        (block.durationMinutes /
                                            totalMinutes) *
                                            totalHeight;

                                    return Positioned(
                                      top: top,
                                      left: 8,
                                      right: 8,
                                      height: height <
                                          40
                                          ? 40
                                          : height,
                                      child:
                                      _buildBlock(
                                          block),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlock(block) {

    Color color;

    switch (block.status) {
      case AppointmentStatus.approved:
        color = Colors.green;
        break;
      case AppointmentStatus.pending:
        color = Colors.orange;
        break;
      case AppointmentStatus.cancelled:
        color = Colors.red;
        break;
      default:
        color = Colors.blueGrey;
    }

    final startHour =
        block.startMinutes ~/ 60;
    final startMinute =
        block.startMinutes % 60;

    final endMinutes =
        block.startMinutes +
            block.durationMinutes;

    final endHour = endMinutes ~/ 60;
    final endMinute =
        endMinutes % 60;

    final timeLabel =
        "${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')} - "
        "${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}";

    return GestureDetector(
      onTap: () =>
          _showDetails(block),
      child: Container(
        padding:
        const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
          color.withOpacity(0.15),
          borderRadius:
          BorderRadius.circular(12),
          border:
          Border.all(color: color),
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              timeLabel,
              style:
              const TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              block.clientLabel,
              style: const TextStyle(
                  fontWeight:
                  FontWeight.bold),
              overflow:
              TextOverflow.ellipsis,
            ),
            Text(
              block.serviceLabel,
              style:
              const TextStyle(fontSize: 12),
              overflow:
              TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(block) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding:
          const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                block.clientLabel,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(block.serviceLabel),
              const SizedBox(height: 8),
              Text(
                  "Status: ${block.status.toString().split('.').last}"),
              const SizedBox(height: 16),

              if (block.status ==
                  AppointmentStatus.pending)
                ElevatedButton(
                  onPressed: () async {
                    await _approveUseCase(
                        block.appointmentId);
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child:
                  const Text("Aprovar"),
                ),

              if (block.status ==
                  AppointmentStatus.approved)
                ElevatedButton(
                  onPressed: () async {
                    await _cancelUseCase(
                        block.appointmentId);
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child:
                  const Text("Cancelar"),
                ),
            ],
          ),
        );
      },
    );
  }
}