import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/modules/scheduling/domain/repositories/scheduling_repository.dart';

class DailyOccupation {
  final DateTime date;
  final int totalMinutes;

  DailyOccupation({
    required this.date,
    required this.totalMinutes,
  });
}

class GetWeeklyOccupationUseCase {
  final SchedulingRepository repository;

  GetWeeklyOccupationUseCase(this.repository);

  Future<List<DailyOccupation>> call({
    required String professionalId,
    required DateTime referenceDate,
  }) async {

    // Descobrir início da semana (segunda)
    final startOfWeek = referenceDate
        .subtract(Duration(days: referenceDate.weekday - 1));

    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final appointments =
    await repository.getByProfessionalAndPeriod(
      professionalId: professionalId,
      start: startOfWeek,
      end: endOfWeek,
    );

    final Map<int, int> minutesByDay = {};

    for (final appointment in appointments) {
      if (appointment.status != AppointmentStatus.approved) {
        continue;
      }

      final day = appointment.scheduledStart.day;

      minutesByDay[day] =
          (minutesByDay[day] ?? 0) +
              appointment.finalDuration.toInt();
    }

    final List<DailyOccupation> result = [];

    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));

      result.add(
        DailyOccupation(
          date: date,
          totalMinutes: minutesByDay[date.day] ?? 0,
        ),
      );
    }

    return result;
  }
}