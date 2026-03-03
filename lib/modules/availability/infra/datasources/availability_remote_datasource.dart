import 'package:fox_link_app/core/database/tenant_firestore.dart';

import '../models/availability_model.dart';
import '../models/daily_override_model.dart';
import '../models/blocked_date_model.dart';

class AvailabilityRemoteDataSource {

  final TenantFirestore firestore;

  AvailabilityRemoteDataSource(this.firestore);

  // ==============================
  // WEEKLY AVAILABILITY
  // ==============================

  Future<void> saveWeeklyAvailability(
      AvailabilityModel model,
      ) async {

    // 🔥 GARANTE QUE O DOCUMENTO SEJA ÚNICO POR PROFISSIONAL + DIA
    final docId = "${model.professionalId}_${model.weekday}";

    await firestore
        .collection('weekly_availability')
        .doc(docId)
        .set(model.toMap());
  }

  Future<AvailabilityModel?> getWeeklyByWeekday({
    required String professionalId,
    required int weekday,
  }) async {

    final query = await firestore
        .collection('weekly_availability')
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

    final query = await firestore
        .collection('weekly_availability')
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

    final normalizedDate =
    DateTime(model.date.year, model.date.month, model.date.day);

    await firestore
        .collection('daily_overrides')
        .doc("${model.professionalId}_${normalizedDate.toIso8601String()}")
        .set(model.toMap());
  }

  Future<DailyOverrideModel?> getDailyOverride({
    required String professionalId,
    required DateTime date,
  }) async {

    final normalizedDate =
    DateTime(date.year, date.month, date.day);

    final query = await firestore
        .collection('daily_overrides')
        .where('professionalId', isEqualTo: professionalId)
        .where('date', isEqualTo: normalizedDate)
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
    await firestore
        .collection('daily_overrides')
        .doc(id)
        .delete();
  }

  // ==============================
  // BLOCKED DATE
  // ==============================

  Future<void> saveBlockedDate(
      BlockedDateModel model,
      ) async {

    final normalizedDate =
    DateTime(model.date.year, model.date.month, model.date.day);

    await firestore
        .collection('blocked_dates')
        .doc("${model.professionalId}_${normalizedDate.toIso8601String()}")
        .set(model.toMap());
  }

  Future<BlockedDateModel?> getBlockedDate({
    required String professionalId,
    required DateTime date,
  }) async {

    final normalizedDate =
    DateTime(date.year, date.month, date.day);

    final query = await firestore
        .collection('blocked_dates')
        .where('professionalId', isEqualTo: professionalId)
        .where('date', isEqualTo: normalizedDate)
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
    await firestore
        .collection('blocked_dates')
        .doc(id)
        .delete();
  }
}