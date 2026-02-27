import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/core/database/tenant_firestore.dart';
import '../../domain/entities/daily_override.dart';
import '../../domain/repositories/daily_override_repository.dart';

class DailyOverrideRepositoryImpl
    implements DailyOverrideRepository {

  final TenantFirestore firestore =
  GetIt.I<TenantFirestore>();

  DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Future<void> save(DailyOverride override) async {

    final normalized = _normalize(override.date);

    await firestore
        .collection('daily_overrides')
        .doc("${override.professionalId}_${normalized.toIso8601String()}")
        .set({
      'professionalId': override.professionalId,
      'date': normalized,
      'isBlocked': override.isBlocked,
      'startMinutes': override.startMinutes,
      'endMinutes': override.endMinutes,
    });
  }

  @override
  Future<DailyOverride?> getByProfessionalAndDate({
    required String professionalId,
    required DateTime date,
  }) async {

    final normalized = _normalize(date);

    final doc = await firestore
        .collection('daily_overrides')
        .doc("${professionalId}_${normalized.toIso8601String()}")
        .get();

    if (!doc.exists) return null;

    final data = doc.data()!;

    return DailyOverride(
      id: doc.id,
      professionalId: data['professionalId'],
      date: (data['date'] as Timestamp).toDate(),
      isBlocked: data['isBlocked'],
      startMinutes: data['startMinutes'],
      endMinutes: data['endMinutes'],
    );
  }

  @override
  Future<void> delete({
    required String professionalId,
    required DateTime date,
  }) async {

    final normalized = _normalize(date);

    await firestore
        .collection('daily_overrides')
        .doc("${professionalId}_${normalized.toIso8601String()}")
        .delete();
  }
}