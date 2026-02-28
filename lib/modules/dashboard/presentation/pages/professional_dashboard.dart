import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:fox_link_app/core/session/tenant_session.dart';
import '../../domain/usecases/get_weekly_timegrid_usecase.dart';

class ProfessionalDashboard extends StatefulWidget {
  const ProfessionalDashboard({super.key});

  @override
  State<ProfessionalDashboard> createState() =>
      _ProfessionalDashboardState();
}

class _ProfessionalDashboardState
    extends State<ProfessionalDashboard> {

  final _session = GetIt.I<TenantSession>();
  final _weeklyTimeGridUseCase =
  GetIt.I<GetWeeklyTimeGridUseCase>();

  DateTime referenceDate = DateTime.now();

  static const double hourHeight = 80;
  static const double startHour = 0;
  static const double totalHours = 24;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7C3AED),
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _daysBar(),
            Expanded(child: _timeGrid()),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // HEADER SEMANA
  // ==========================================================

  Widget _header() {
    final startOfWeek =
    referenceDate.subtract(Duration(days: referenceDate.weekday - 1));
    final endOfWeek =
    startOfWeek.add(const Duration(days: 6));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                referenceDate =
                    referenceDate.subtract(const Duration(days: 7));
              });
            },
            icon: const Icon(Icons.chevron_left, color: Colors.white),
          ),
          Column(
            children: [
              Text(
                "${startOfWeek.day} - ${endOfWeek.day} ${_monthLabel(referenceDate.month)} ${referenceDate.year}",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () {
                  setState(() {
                    referenceDate = DateTime.now();
                  });
                },
                child: const Text(
                  "Hoje",
                  style: TextStyle(color: Colors.white70),
                ),
              )
            ],
          ),
          IconButton(
            onPressed: () {
              setState(() {
                referenceDate =
                    referenceDate.add(const Duration(days: 7));
              });
            },
            icon: const Icon(Icons.chevron_right, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BARRA DIAS
  // ==========================================================

  Widget _daysBar() {
    final startOfWeek =
    referenceDate.subtract(Duration(days: referenceDate.weekday - 1));

    return Container(
      color: const Color(0xFF111827),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: List.generate(7, (index) {
          final day = startOfWeek.add(Duration(days: index));
          final isToday =
          _isSameDay(day, DateTime.now());

          return Expanded(
            child: Column(
              children: [
                Text(
                  _weekdayLabel(day.weekday),
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFF7C3AED)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "${day.day}",
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ==========================================================
  // GRADE HORÁRIA
  // ==========================================================

  Widget _timeGrid() {
    return FutureBuilder(
      future: _weeklyTimeGridUseCase(
        professionalId: _session.uid!,
        referenceDate: referenceDate,
      ),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator());
        }

        final blocks = snapshot.data!;

        final gridHeight = totalHours * hourHeight;

        return SingleChildScrollView(
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

                      // linhas
                      Column(
                        children: List.generate(
                          totalHours.toInt(),
                              (i) => Container(
                            height: hourHeight,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                    color: Colors.white12),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // blocos
                      ...dayBlocks.map((block) {

                        final top =
                            (block.startMinutes / 60) *
                                hourHeight;
                        final height =
                            (block.durationMinutes / 60) *
                                hourHeight;

                        return Positioned(
                          top: top,
                          left: 4,
                          right: 4,
                          height: height,
                          child: Container(
                            padding:
                            const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient:
                              const LinearGradient(
                                colors: [
                                  Color(0xFF22C55E),
                                  Color(0xFF16A34A)
                                ],
                              ),
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "Cliente",
                                  style: TextStyle(
                                      fontSize: 11,
                                      color:
                                      Colors.white,
                                      fontWeight:
                                      FontWeight.bold),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "09:00 - 10:00",
                                  style: TextStyle(
                                      fontSize: 10,
                                      color:
                                      Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  String _weekdayLabel(int weekday) {
    const labels = [
      "Seg",
      "Ter",
      "Qua",
      "Qui",
      "Sex",
      "Sab",
      "Dom"
    ];
    return labels[weekday - 1];
  }

  String _monthLabel(int month) {
    const months = [
      "Jan",
      "Fev",
      "Mar",
      "Abr",
      "Mai",
      "Jun",
      "Jul",
      "Ago",
      "Set",
      "Out",
      "Nov",
      "Dez"
    ];
    return months[month - 1];
  }
}