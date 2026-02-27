import '../entities/daily_override.dart';

abstract class DailyOverrideRepository {

  Future<void> save(DailyOverride override);

  Future<DailyOverride?> getByProfessionalAndDate({
    required String professionalId,
    required DateTime date,
  });

  Future<void> delete({
    required String professionalId,
    required DateTime date,
  });
}