import '../repositories/availability_repository.dart';
import '../entities/daily_override.dart';
import '../entities/blocked_date.dart';

class MonthlyAvailabilityDay {
  final DateTime date;
  final bool isActive;
  final bool isBlocked;

  MonthlyAvailabilityDay({
    required this.date,
    required this.isActive,
    required this.isBlocked,
  });
}

class GetMonthlyAvailabilityUseCase {
  final AvailabilityRepository repository;

  GetMonthlyAvailabilityUseCase(this.repository);

  Future<List<MonthlyAvailabilityDay>> call({
    required String professionalId,
    required DateTime month,
  }) async {

    final lastDay =
    DateTime(month.year, month.month + 1, 0);

    final weekly =
    await repository.getWeeklyAvailabilityByProfessional(
        professionalId);

    final List<MonthlyAvailabilityDay> result = [];

    for (int day = 1; day <= lastDay.day; day++) {

      final date =
      DateTime(month.year, month.month, day);

      final weekday = date.weekday;

      final weeklyMatch = weekly
          .where((w) => w.weekday == weekday)
          .toList();

      bool isActive = false;

      if (weeklyMatch.isNotEmpty) {
        final weeklyDay = weeklyMatch.first;

        // 🔥 Proteção contra estado inválido
        if (weeklyDay.isActive && weeklyDay.shifts.isEmpty) {
          isActive = false;
        } else {
          isActive = weeklyDay.isActive;
        }
      }

      final blocked =
      await repository.getBlockedDate(
        professionalId: professionalId,
        date: date,
      );

      final override =
      await repository.getDailyOverride(
        professionalId: professionalId,
        date: date,
      );

      if (override != null) {
        isActive = true;
      }

      if (blocked != null) {
        isActive = false;
      }

      result.add(
        MonthlyAvailabilityDay(
          date: date,
          isActive: isActive,
          isBlocked: blocked != null,
        ),
      );
    }

    return result;
  }
}