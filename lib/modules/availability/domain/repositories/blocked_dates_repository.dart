abstract class BlockedDatesRepository {

  /// 🔴 Bloqueia um dia específico do profissional
  Future<void> blockDate({
    required String professionalId,
    required DateTime date,
    required String reason,
  });

  /// 🔍 Verifica se o dia está bloqueado
  Future<bool> isDateBlocked({
    required String professionalId,
    required DateTime date,
  });

  /// 📋 Lista todos bloqueios de um profissional
  Future<List<DateTime>> getBlockedDates(
      String professionalId);

  /// ❌ Remove bloqueio
  Future<void> unblockDate({
    required String professionalId,
    required DateTime date,
  });
}