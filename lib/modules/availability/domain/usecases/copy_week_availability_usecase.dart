import '../entities/availability.dart';
import '../repositories/availability_repository.dart';

class CopyWeekAvailabilityUseCase {

  final AvailabilityRepository repository;

  CopyWeekAvailabilityUseCase(this.repository);

  Future<void> call({
    required String professionalId,
    required int sourceWeekday,
  }) async {

    final all =
    await repository.getWeeklyAvailabilityByProfessional(
      professionalId,
    );

    final source = all.firstWhere(
          (a) => a.weekday == sourceWeekday,
      orElse: () => throw Exception(
          "Dia origem não configurado."),
    );

    for (int weekday = 1; weekday <= 7; weekday++) {

      if (weekday == sourceWeekday) continue;

      final replicatedAvailability = Availability(
        id: '${professionalId}_$weekday',
        professionalId: professionalId,
        weekday: weekday,
        isActive: source.isActive,
        shifts: List.from(source.shifts),
        slotIntervalMinutes: source.slotIntervalMinutes,
        breakTimes: List.from(source.breakTimes), // ✅ CORRIGIDO
      );

      await repository.saveWeeklyAvailability(
          replicatedAvailability);
    }
  }
}