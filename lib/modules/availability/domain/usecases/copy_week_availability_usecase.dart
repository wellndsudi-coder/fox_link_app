import '../entities/availability.dart';
import '../repositories/availability_repository.dart';

/// UseCase responsável por copiar a disponibilidade
/// de um dia específico para todos os outros dias da semana.
///
/// Regras:
/// - Sobrescreve todos os dias (exceto o dia origem)
/// - Mantém mesmo padrão de shifts
/// - Não altera DailyOverride
/// - Não altera BlockedDate
/// - Não acessa Firestore direto
/// - Mantém ID determinístico: professionalId_weekday
class CopyWeekAvailabilityUseCase {
  final AvailabilityRepository repository;

  CopyWeekAvailabilityUseCase(this.repository);

  Future<void> call({
    required String professionalId,
    required int sourceWeekday,
  }) async {
    // 1️⃣ Buscar disponibilidade base
    final sourceAvailability =
    await repository.getWeeklyAvailabilityByWeekday(
      professionalId: professionalId,
      weekday: sourceWeekday,
    );

    if (sourceAvailability == null) {
      throw Exception(
        "Disponibilidade base não encontrada para o dia selecionado.",
      );
    }

    // 2️⃣ Replicar para todos os dias da semana (1..7)
    for (int weekday = 1; weekday <= 7; weekday++) {
      if (weekday == sourceWeekday) continue;

      final replicatedAvailability = Availability(
        id: '${professionalId}_$weekday',
        professionalId: professionalId,
        weekday: weekday,
        isActive: sourceAvailability.isActive,
        shifts: sourceAvailability.shifts,
      );

      await repository.saveWeeklyAvailability(
        replicatedAvailability,
      );
    }
  }
}