import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/modules/scheduling/domain/repositories/scheduling_repository.dart';

class WeeklyScheduleView {
  final DateTime date;
  final List<Appointment> appointments;

  WeeklyScheduleView({
    required this.date,
    required this.appointments,
  });
}

class GetWeeklyScheduleUseCase {
  final SchedulingRepository repository;

  GetWeeklyScheduleUseCase(this.repository);

  Future<List<WeeklyScheduleView>> call({
    required String professionalId,
    required DateTime referenceDate,
  }) async {

    final startOfWeek =
    referenceDate.subtract(Duration(days: referenceDate.weekday - 1));

    final endOfWeek =
    startOfWeek.add(const Duration(days: 7));

    final appointments =
    await repository.getByProfessionalAndPeriod(
      professionalId: professionalId,
      start: startOfWeek,
      end: endOfWeek,
    );

    final Map<int, List<Appointment>> grouped = {};

    for (final appointment in appointments) {
      if (appointment.status != AppointmentStatus.approved) continue;

      final day = appointment.scheduledStart.day;

      grouped.putIfAbsent(day, () => []);
      grouped[day]!.add(appointment);
    }

    final List<WeeklyScheduleView> result = [];

    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));

      result.add(
        WeeklyScheduleView(
          date: date,
          appointments: grouped[date.day] ?? [],
        ),
      );
    }

    return result;
  }
}