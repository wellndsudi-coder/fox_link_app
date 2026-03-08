import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fox_link_app/core/database/tenant_firestore.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/entities/waiting_list_entry.dart';

abstract class WaitingListRemoteDataSource {
  Future<String> add({
    required String clientId,
    required String serviceId,
    required DateTime desiredDate,
    String? professionalId,
    DateTime? desiredTime,
  });

  Future<List<WaitingListEntry>> getByClient(String clientId);

  Future<List<WaitingListEntry>> getByDesiredDate(DateTime date);

  Future<List<WaitingListEntry>> getByProfessionalAndDate({
    required String professionalId,
    required DateTime date,
  });

  Future<List<WaitingListEntry>> getPendingByService(String serviceId);

  Future<WaitingListEntry?> getFirstPendingForService(String serviceId);

  Future<void> updateStatus(String entryId, WaitingListStatus status);

  Future<void> offerSlot({
    required String entryId,
    required DateTime slotStart,
    required DateTime slotEnd,
  });
}

class WaitingListRemoteDataSourceImpl implements WaitingListRemoteDataSource {
  final TenantFirestore firestore;

  WaitingListRemoteDataSourceImpl(this.firestore);

  CollectionReference<Map<String, dynamic>> get _col =>
      firestore.collection('waiting_list');

  @override
  Future<String> add({
    required String clientId,
    required String serviceId,
    required DateTime desiredDate,
    String? professionalId,
    DateTime? desiredTime,
  }) async {
    final ref = await _col.add({
      'clientId': clientId,
      'serviceId': serviceId,
      'desiredDate': _dateKey(desiredDate),
      'desiredTime': desiredTime?.toIso8601String(),
      'professionalId': professionalId,
      'createdAt': FieldValue.serverTimestamp(),
      'status': WaitingListStatus.pending.name,
    });
    return ref.id;
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<List<WaitingListEntry>> getByClient(String clientId) async {
    final snapshot = await _col
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map(_fromDoc).toList();
  }

  @override
  Future<List<WaitingListEntry>> getPendingByService(String serviceId) async {
    final snapshot = await _col
        .where('serviceId', isEqualTo: serviceId)
        .where('status', isEqualTo: WaitingListStatus.pending.name)
        .orderBy('createdAt')
        .get();
    return snapshot.docs.map(_fromDoc).toList();
  }

  @override
  Future<WaitingListEntry?> getFirstPendingForService(String serviceId) async {
    final list = await getPendingByService(serviceId);
    return list.isEmpty ? null : list.first;
  }

  @override
  Future<void> updateStatus(String entryId, WaitingListStatus status) async {
    await _col.doc(entryId).update({'status': status.name});
  }

  @override
  Future<void> offerSlot({
    required String entryId,
    required DateTime slotStart,
    required DateTime slotEnd,
  }) async {
    await _col.doc(entryId).update({
      'status': WaitingListStatus.slotOffered.name,
      'offeredSlotStart': Timestamp.fromDate(slotStart),
      'offeredSlotEnd': Timestamp.fromDate(slotEnd),
      'offeredAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<WaitingListEntry>> getByDesiredDate(DateTime date) async {
    final key = _dateKey(date);
    final snapshot = await _col
        .where('desiredDate', isEqualTo: key)
        .orderBy('createdAt')
        .get();
    return snapshot.docs
        .map(_fromDoc)
        .where((e) => e.status != WaitingListStatus.cancelled)
        .toList();
  }

  @override
  Future<List<WaitingListEntry>> getByProfessionalAndDate({
    required String professionalId,
    required DateTime date,
  }) async {
    final key = _dateKey(date);
    final snapshot = await _col
        .where('desiredDate', isEqualTo: key)
        .where('professionalId', isEqualTo: professionalId)
        .orderBy('createdAt')
        .get();
    return snapshot.docs
        .map(_fromDoc)
        .where((e) => e.status != WaitingListStatus.cancelled)
        .toList();
  }

  WaitingListEntry _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final createdAt = d['createdAt'];
    DateTime created;
    if (createdAt is Timestamp) {
      created = createdAt.toDate();
    } else {
      created = DateTime.now();
    }
    final desiredTimeStr = d['desiredTime'] as String?;
    final desiredDateStr = d['desiredDate'] as String?;
    DateTime desiredDate;
    if (desiredDateStr != null) {
      final parts = desiredDateStr.split('-');
      if (parts.length == 3) {
        desiredDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      } else {
        desiredDate = created;
      }
    } else {
      desiredDate = desiredTimeStr != null
          ? DateTime.tryParse(desiredTimeStr) ?? created
          : DateTime(created.year, created.month, created.day);
    }
    final statusStr = d['status'] as String? ?? 'pending';
    final status = statusStr == 'notified'
        ? WaitingListStatus.clientNotified
        : WaitingListStatus.values.firstWhere(
            (e) => e.name == statusStr,
            orElse: () => WaitingListStatus.pending,
          );
    final offeredStart = d['offeredSlotStart'] as Timestamp?;
    final offeredEnd = d['offeredSlotEnd'] as Timestamp?;
    final offeredAtTs = d['offeredAt'] as Timestamp?;
    return WaitingListEntry(
      id: doc.id,
      clientId: d['clientId'] as String,
      serviceId: d['serviceId'] as String,
      professionalId: d['professionalId'] as String?,
      desiredDate: desiredDate,
      desiredTime: desiredTimeStr != null
          ? DateTime.tryParse(desiredTimeStr)
          : null,
      createdAt: created,
      status: status,
      offeredSlotStart: offeredStart?.toDate(),
      offeredSlotEnd: offeredEnd?.toDate(),
      offeredAt: offeredAtTs?.toDate(),
    );
  }
}
