import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/session/tenant_session.dart';
import '../../domain/usecases/get_monthly_availability_usecase.dart';
import 'daily_availability_page.dart';

class MonthlyAvailabilityPage extends StatefulWidget {
  const MonthlyAvailabilityPage({super.key});

  @override
  State<MonthlyAvailabilityPage> createState() =>
      _MonthlyAvailabilityPageState();
}

class _MonthlyAvailabilityPageState
    extends State<MonthlyAvailabilityPage> {

  final _session = GetIt.I<TenantSession>();
  final _useCase =
  GetIt.I<GetMonthlyAvailabilityUseCase>();

  DateTime focusedMonth = DateTime.now();

  Future<List<MonthlyAvailabilityDay>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _useCase(
      professionalId: _session.uid!,
      month: focusedMonth,
    );
  }

  void _reloadMonth(DateTime month) {
    setState(() {
      focusedMonth = month;
      _future = _useCase(
        professionalId: _session.uid!,
        month: focusedMonth,
      );
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Disponibilidade Mensal"),
      ),
      body: FutureBuilder<List<MonthlyAvailabilityDay>>(
        future: _future,
        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erro: ${snapshot.error}",
              ),
            );
          }

          final days = snapshot.data ?? [];

          return TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2100),
            focusedDay: focusedMonth,
            calendarFormat: CalendarFormat.month,
            onPageChanged: (month) {
              _reloadMonth(month);
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, date, _) {

                final data = days.firstWhere(
                      (d) =>
                  d.date.year == date.year &&
                      d.date.month == date.month &&
                      d.date.day == date.day,
                  orElse: () => MonthlyAvailabilityDay(
                    date: date,
                    isActive: false,
                    isBlocked: false,
                  ),
                );

                Color bgColor = Colors.white;

                if (data.isBlocked) {
                  bgColor = Colors.red.shade200;
                } else if (data.isActive) {
                  bgColor = Colors.green.shade200;
                }

                return Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius:
                    BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      date.day.toString(),
                      style: const TextStyle(
                        color: Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
            onDaySelected: (selected, _) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DailyAvailabilityPage(
                        date: selected,
                      ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}