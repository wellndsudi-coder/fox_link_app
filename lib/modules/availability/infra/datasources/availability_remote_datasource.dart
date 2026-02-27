import 'package:fox_link_app/core/firestore/tenant_firestore.dart';

import '../models/availability_model.dart';
import '../models/daily_override_model.dart';
import '../models/blocked_date_model.dart';

class AvailabilityRemoteDataSource {
  // ==============================
  // WEEKLY AVAILABILITY
  // ==============================

  Future<void> saveWeeklyAvailability(
      AvailabilityModel model,
      ) async {
    await TenantFirestore.collection('weekly_availability')
        .doc(model.id)
        .set(model.toMap());
  }

  Future<AvailabilityModel?> getWeeklyByWeekday({
    required String professionalId,
    required int weekday,
  }) async {
    final query = await TenantFirestore.collection('weekly_availability')
        .where('professionalId', isEqualTo: professionalId)
        .where('weekday', isEqualTo: weekday)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;

    return AvailabilityModel.fromMap(
      doc.data(),
      doc.id,
    );
  }

  Future<List<AvailabilityModel>> getWeeklyByProfessional(
      String professionalId,
      ) async {
    final query = await TenantFirestore.collection('weekly_availability')
        .where('professionalId', isEqualTo: professionalId)
        .get();

    return query.docs
        .map((doc) =>
        AvailabilityModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ==============================
  // DAILY OVERRIDE
  // ==============================

  Future<void> saveDailyOverride(
      DailyOverrideModel model,
      ) async {
    await TenantFirestore.collection('daily_overrides')
        .doc(model.id)
        .set(model.toMap());
  }

  Future<DailyOverrideModel?> getDailyOverride({
    required String professionalId,
    required DateTime date,
  }) async {
    final query = await TenantFirestore.collection('daily_overrides')
        .where('professionalId', isEqualTo: professionalId)
        .where('date', isEqualTo: date)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;

    return DailyOverrideModel.fromMap(
      doc.data(),
      doc.id,
    );
  }

  Future<void> removeDailyOverride(String id) async {
    await TenantFirestore.collection('daily_overrides')
        .doc(id)
        .delete();
  }

  // ==============================
  // BLOCKED DATE
  // ==============================

  Future<void> saveBlockedDate(
      BlockedDateModel model,
      ) async {
    await TenantFirestore.collection('blocked_dates')
        .doc(model.id)
        .set(model.toMap());
  }

  Future<BlockedDateModel?> getBlockedDate({
    required String professionalId,
    required DateTime date,
  }) async {
    final query = await TenantFirestore.collection('blocked_dates')
        .where('professionalId', isEqualTo: professionalId)
        .where('date', isEqualTo: date)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;

    return BlockedDateModel.fromMap(
      doc.data(),
      doc.id,
    );
  }

  Future<void> removeBlockedDate(String id) async {
    await TenantFirestore.collection('blocked_dates')
        .doc(id)
        .delete();
  }
}