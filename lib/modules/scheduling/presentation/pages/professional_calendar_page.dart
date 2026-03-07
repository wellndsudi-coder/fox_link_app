import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/modules/scheduling/domain/repositories/scheduling_repository.dart';
import 'package:fox_link_app/modules/availability/domain/repositories/availability_repository.dart';
import 'package:fox_link_app/modules/availability/domain/repositories/blocked_dates_repository.dart';

class ProfessionalCalendarPage extends StatefulWidget {
  const ProfessionalCalendarPage({super.key});

  @override
  State<ProfessionalCalendarPage> createState() =>
      _ProfessionalCalendarPageState();
}

class _ProfessionalCalendarPageState
    extends State<ProfessionalCalendarPage> {

  final _repository =
  GetIt.I<SchedulingRepository>();

  final _availabilityRepo =
  GetIt.I<AvailabilityRepository>();

  final _blockedRepo =
  GetIt.I<BlockedDatesRepository>();

  final _session =
  GetIt.I<TenantSession>();

  DateTime selectedDay = DateTime.now();

  Map<DateTime, double> occupationMap = {};

  @override
  void initState() {
    super.initState();
    _loadMonthOccupation();
  }

  // ==========================================================
  // 🔥 CALCULAR OCUPAÇÃO DO MÊS
  // ==========================================================
  Future<void> _loadMonthOccupation() async {

    final firstDay =
    DateTime(selectedDay.year, selectedDay.month, 1);

    final lastDay =
    DateTime(selectedDay.year, selectedDay.month + 1, 0);

    for (DateTime day = firstDay;
    day.isBefore(lastDay.add(const Duration(days: 1)));
    day = day.add(const Duration(days: 1))) {

      final isBlocked =
      await _blockedRepo.isDateBlocked(
        professionalId: _session.uid!,
        date: day,
      );

      if (isBlocked) {
        occupationMap[day] = -1; // 🔴 bloqueado
        continue;
      }

      final availabilityList =
      await _availabilityRepo.getWeeklyAvailabilityByProfessional(
        _session.uid!,
      );

      final weekday = day.weekday;

      final availability = availabilityList.where(
            (a) => a.weekday == weekday,
      ).toList();

      if (availability.isEmpty) {
        occupationMap[day] = 0;
        continue;
      }

      final totalAvailableMinutes =
          availability.first.endMinutes -
              availability.first.startMinutes;

      final appointments =
      await _repository
          .getApprovedByProfessionalAndDate(
        professionalId: _session.uid!,
        date: day,
      );

      final usedMinutes =
      appointments.fold<int>(
        0,
            (sum, a) =>
        sum + a.finalDuration,
      );

      final percent =
          usedMinutes / totalAvailableMinutes;

      occupationMap[day] = percent;
    }

    setState(() {});
  }

  // ==========================================================
  Color _getColor(BuildContext context, DateTime day) {

    final key =
    DateTime(day.year, day.month, day.day);

    if (!occupationMap.containsKey(key)) {
      return Colors.transparent;
    }

    final value = occupationMap[key]!;

    if (value == -1) {
      return AppColors.error(context); // bloqueado
    }

    if (value >= 0.9) {
      return AppColors.error(context); // cheio
    }

    if (value > 0.4) {
      return AppColors.warning(context); // parcial
    }

    if (value > 0) {
      return AppColors.success(context); // leve ocupação
    }

    return Colors.transparent;
  }

  // ==========================================================
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Agenda Profissional"),
      ),
      body: TableCalendar(
        firstDay: DateTime(2020),
        lastDay: DateTime(2100),
        focusedDay: selectedDay,
        selectedDayPredicate:
            (day) =>
            isSameDay(day, selectedDay),
        onDaySelected:
            (selected, _) {
          setState(() {
            selectedDay = selected;
          });
        },
        calendarBuilders:
        CalendarBuilders(
          defaultBuilder:
              (context, day, _) {

            final color =
            _getColor(context, day);

            if (color ==
                Colors.transparent) {
              return null;
            }

            return Container(
              margin:
              const EdgeInsets.all(4),
              decoration:
              BoxDecoration(
                color: color,
                shape:
                BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  "${day.day}",
                  style:
                  TextStyle(
                    color:
                    Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}