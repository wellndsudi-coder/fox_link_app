import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:fox_link_app/core/database/tenant_firestore.dart';
import '../../domain/repositories/blocked_dates_repository.dart';

class BlockedDatesRepositoryImpl
    implements BlockedDatesRepository {

  final TenantFirestore firestore =
  GetIt.I<TenantFirestore>();

  DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Future<void> blockDate({
    required String professionalId,
    required DateTime date,
    required String reason,
  }) async {

    final normalized = _normalize(date);

    await firestore
        .collection('blocked_dates')
        .add({
      'professionalId': professionalId,
      'date': normalized,
      'reason': reason,
      'createdAt':
      FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<bool> isDateBlocked({
    required String professionalId,
    required DateTime date,
  }) async {

    final normalized = _normalize(date);

    final snapshot = await firestore
        .collection('blocked_dates')
        .where('professionalId',
        isEqualTo: professionalId)
        .where('date',
        isEqualTo: normalized)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  @override
  Future<List<DateTime>> getBlockedDates(
      String professionalId) async {

    final snapshot = await firestore
        .collection('blocked_dates')
        .where('professionalId',
        isEqualTo: professionalId)
        .get();

    return snapshot.docs
        .map((doc) =>
        (doc['date'] as Timestamp)
            .toDate())
        .toList();
  }

  @override
  Future<void> unblockDate({
    required String professionalId,
    required DateTime date,
  }) async {

    final normalized = _normalize(date);

    final snapshot = await firestore
        .collection('blocked_dates')
        .where('professionalId',
        isEqualTo: professionalId)
        .where('date',
        isEqualTo: normalized)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}