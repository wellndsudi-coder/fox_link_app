import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_weekly_timegrid_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/approve_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/cancel_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/request_reschedule_usecase.dart';

class ProfessionalAgendaPage extends StatefulWidget {
  const ProfessionalAgendaPage({super.key});

  @override
  State<ProfessionalAgendaPage> createState() =>
      _ProfessionalAgendaPageState();
}

class _ProfessionalAgendaPageState
    extends State<ProfessionalAgendaPage> {

  final _session = GetIt.I<TenantSession>();
  final _timeGridUseCase =
  GetIt.I<GetWeeklyTimeGridUseCase>();

  final _approveUseCase =
  GetIt.I<ApproveAppointmentUseCase>();

  final _cancelUseCase =
  GetIt.I<CancelAppointmentUseCase>();

  final _rescheduleUseCase =
  GetIt.I<RequestRescheduleUseCase>();

  late Future _future;

  DateTime referenceDate = DateTime.now();

  static const double hourHeight = 80;
  static const double totalHours = 13;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _timeGridUseCase(
      professionalId: _session.uid!,
      referenceDate: referenceDate,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Minha Agenda"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final blocks = snapshot.data!;
          final gridHeight = totalHours * hourHeight;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics:
              const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: gridHeight,
                child: Row(
                  children: List.generate(7, (index) {

                    final weekday = index + 1;

                    final dayBlocks = blocks
                        .where((b) => b.weekday == weekday)
                        .toList();

                    return Expanded(
                      child: Stack(
                        children: [

                          Column(
                            children: List.generate(
                              totalHours.toInt(),
                                  (i) => Container(
                                height: hourHeight,
                                decoration:
                                const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color:
                                      Color(0xFFE2E8F0),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          ...dayBlocks.map((block) {

                            final top =
                                block.topFactor *
                                    gridHeight;

                            final height =
                                block.heightFactor *
                                    gridHeight;

                            return Positioned(
                              top: top,
                              left: 6,
                              right: 6,
                              height: height,
                              child: _buildBlock(block),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
          );
        },
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
      case AppointmentStatus.rescheduleRequested:
        color = Colors.purple;
        break;
      case AppointmentStatus.completed:
        color = Colors.blueGrey;
        break;
      default:
        color = Colors.grey;
    }

    return GestureDetector(
      onTap: () => _showDetails(block),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              block.clientName,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              block.serviceName,
              style: const TextStyle(
                  fontSize: 11),
              overflow: TextOverflow.ellipsis,
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [

              Text(block.clientName,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium),

              const SizedBox(height: 8),
              Text(block.serviceName),
              const SizedBox(height: 8),
              Text("Status: ${block.status.name}"),
              const SizedBox(height: 16),

              if (block.status ==
                  AppointmentStatus.pending)
                ElevatedButton(
                  onPressed: () async {
                    await _approveUseCase(
                        block.appointmentId);
                    Navigator.pop(context);
                    _refresh();
                  },
                  child: const Text("Aprovar"),
                ),

              if (block.status ==
                  AppointmentStatus.approved)
                ElevatedButton(
                  onPressed: () async {
                    await _cancelUseCase(
                      block.appointmentId,
                    );
                    Navigator.pop(context);
                    _refresh();
                  },
                  child: const Text("Cancelar"),
                ),
            ],
          ),
        );
      },
    );
  }
}