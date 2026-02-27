import '../../domain/entities/availability.dart';
import '../../domain/entities/daily_override.dart';
import '../../domain/entities/blocked_date.dart';
import '../../domain/repositories/availability_repository.dart';

import '../datasources/availability_remote_datasource.dart';
import '../models/availability_model.dart';
import '../models/daily_override_model.dart';
import '../models/blocked_date_model.dart';

class AvailabilityRepositoryImpl implements AvailabilityRepository {
  final AvailabilityRemoteDataSource remoteDataSource;

  AvailabilityRepositoryImpl(this.remoteDataSource);

  // ===============================
  // WEEKLY BASE
  // ===============================

  @override
  Future<void> saveWeeklyAvailability(
      Availability availability) async {
    final model = AvailabilityModel(
      id: availability.id,
      professionalId: availability.professionalId,
      weekday: availability.weekday,
      startMinutes: availability.startMinutes,
      endMinutes: availability.endMinutes,
      breakStartMinutes: availability.breakStartMinutes,
      breakEndMinutes: availability.breakEndMinutes,
    );

    await remoteDataSource.saveWeeklyAvailability(model);
  }

  @override
  Future<Availability?> getWeeklyAvailabilityByWeekday({
    required String professionalId,
    required int weekday,
  }) async {
    return await remoteDataSource.getWeeklyByWeekday(
      professionalId: professionalId,
      weekday: weekday,
    );
  }

  @override
  Future<List<Availability>>
  getWeeklyAvailabilityByProfessional(
      String professionalId) async {
    return await remoteDataSource
        .getWeeklyByProfessional(professionalId);
  }

  // ===============================
  // DAILY OVERRIDE
  // ===============================

  @override
  Future<void> saveDailyOverride(
      DailyOverride override) async {
    final model = DailyOverrideModel(
      id: override.id,
      professionalId: override.professionalId,
      date: override.date,
      startMinutes: override.startMinutes,
      endMinutes: override.endMinutes,
    );

    await remoteDataSource.saveDailyOverride(model);
  }

  @override
  Future<DailyOverride?> getDailyOverride({
    required String professionalId,
    required DateTime date,
  }) async {
    return await remoteDataSource.getDailyOverride(
      professionalId: professionalId,
      date: date,
    );
  }

  @override
  Future<void> removeDailyOverride(
      String overrideId) async {
    await remoteDataSource.removeDailyOverride(
        overrideId);
  }

  // ===============================
  // BLOCKED DATE
  // ===============================

  @override
  Future<void> saveBlockedDate(
      BlockedDate blockedDate) async {
    final model = BlockedDateModel(
      id: blockedDate.id,
      professionalId: blockedDate.professionalId,
      date: blockedDate.date,
    );

    await remoteDataSource.saveBlockedDate(model);
  }

  @override
  Future<BlockedDate?> getBlockedDate({
    required String professionalId,
    required DateTime date,
  }) async {
    return await remoteDataSource.getBlockedDate(
      professionalId: professionalId,
      date: date,
    );
  }

  @override
  Future<void> removeBlockedDate(
      String blockedDateId) async {
    await remoteDataSource.removeBlockedDate(
        blockedDateId);
  }
}