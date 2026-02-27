import '../entities/availability.dart';
import '../entities/daily_override.dart';
import '../entities/blocked_date.dart';

abstract class AvailabilityRepository {
  // ===============================
  // WEEKLY BASE
  // ===============================

  Future<void> saveWeeklyAvailability(Availability availability);

  Future<Availability?> getWeeklyAvailabilityByWeekday({
    required String professionalId,
    required int weekday,
  });

  Future<List<Availability>> getWeeklyAvailabilityByProfessional(
      String professionalId,
      );

  // ===============================
  // DAILY OVERRIDE
  // ===============================

  Future<void> saveDailyOverride(DailyOverride override);

  Future<DailyOverride?> getDailyOverride({
    required String professionalId,
    required DateTime date,
  });

  Future<void> removeDailyOverride(String overrideId);

  // ===============================
  // BLOCKED DATE
  // ===============================

  Future<void> saveBlockedDate(BlockedDate blockedDate);

  Future<BlockedDate?> getBlockedDate({
    required String professionalId,
    required DateTime date,
  });

  Future<void> removeBlockedDate(String blockedDateId);
}