import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fox_link_app/core/database/tenant_firestore.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/waitlist/domain/entities/waitlist_entry.dart';

abstract class WaitlistRemoteDataSource {
  Stream<List<WaitlistEntry>> streamWeeklyWaitlist(String? professionalId);
  Future<void> updateStatus(String id, WaitlistStatus status);
}

class WaitlistRemoteDataSourceImpl implements WaitlistRemoteDataSource {
  final TenantFirestore firestore;
  final TenantSession session;

  WaitlistRemoteDataSourceImpl(this.firestore, this.session);

  static DateTime _mondayOfWeek(DateTime date) {
    return DateTime(date.year, date.month, date.day - (date.weekday - 1));
  }

  static DateTime _sundayOfWeek(DateTime date) {
    final monday = _mondayOfWeek(date);
    return monday.add(const Duration(days: 6));
  }

  @override
  Stream<List<WaitlistEntry>> streamWeeklyWaitlist(String? professionalId) {
    final tenantId = session.tenantId;
    if (tenantId == null) return Stream.value([]);
    if (professionalId == null || professionalId.isEmpty) {
      return Stream.value([]);
    }

    final now = DateTime.now();
    final monday = _mondayOfWeek(now);
    final sunday = _sundayOfWeek(now);
    final mondayTimestamp = Timestamp.fromDate(monday);
    final sundayTimestamp = Timestamp.fromDate(sunday);

    return firestore
        .collection('waitlist')
        .where('status', isEqualTo: WaitlistStatus.waiting.name)
        .where('professionalId', isEqualTo: professionalId)
        .where('desiredDate', isGreaterThanOrEqualTo: mondayTimestamp)
        .where('desiredDate', isLessThanOrEqualTo: sundayTimestamp)
        .orderBy('desiredDate')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _fromDoc(doc))
            .where((e) => e != null)
            .cast<WaitlistEntry>()
            .toList());
  }

  WaitlistEntry? _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    try {
      final desiredDate = _parseDate(d['desiredDate']);
      final createdAt = _parseTimestamp(d['createdAt']);
      if (desiredDate == null || createdAt == null) return null;

      final statusStr = d['status'] as String? ?? 'waiting';
      final status = WaitlistStatus.values.firstWhere(
        (s) => s.name == statusStr,
        orElse: () => WaitlistStatus.waiting,
      );

      return WaitlistEntry(
        id: doc.id,
        clientName: d['clientName'] as String? ?? 'Cliente',
        clientPhone: d['clientPhone'] as String?,
        serviceName: d['serviceName'] as String? ?? 'Serviço',
        serviceId: d['serviceId'] as String?,
        clientId: d['clientId'] as String?,
        professionalId: d['professionalId'] as String?,
        desiredDate: desiredDate,
        createdAt: createdAt,
        status: status,
      );
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  DateTime? _parseTimestamp(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  @override
  Future<void> updateStatus(String id, WaitlistStatus status) async {
    await firestore.collection('waitlist').doc(id).update({
      'status': status.name,
    });
  }
}
