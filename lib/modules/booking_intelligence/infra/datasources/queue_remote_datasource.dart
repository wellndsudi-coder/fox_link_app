import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fox_link_app/core/database/tenant_firestore.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/entities/queue_entry.dart';

abstract class QueueRemoteDataSource {
  Future<QueueEntry> add(String clientId);

  Future<QueueEntry?> getByClient(String clientId);

  Future<void> remove(String clientId);

  Future<List<QueueEntry>> getAll();
}

class QueueRemoteDataSourceImpl implements QueueRemoteDataSource {
  final TenantFirestore firestore;

  QueueRemoteDataSourceImpl(this.firestore);

  CollectionReference<Map<String, dynamic>> get _col =>
      firestore.collection('queue');

  @override
  Future<QueueEntry> add(String clientId) async {
    final existing = await getByClient(clientId);
    if (existing != null) return existing;

    final all = await getAll();
    final position = all.length + 1;
    final estimated = DateTime.now().add(Duration(minutes: position * 15));

    final ref = await _col.add({
      'clientId': clientId,
      'position': position,
      'estimatedTime': Timestamp.fromDate(estimated),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return QueueEntry(
      id: ref.id,
      clientId: clientId,
      position: position,
      estimatedTime: estimated,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<QueueEntry?> getByClient(String clientId) async {
    final snapshot = await _col
        .where('clientId', isEqualTo: clientId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return _fromDoc(snapshot.docs.first);
  }

  @override
  Future<void> remove(String clientId) async {
    final snapshot = await _col
        .where('clientId', isEqualTo: clientId)
        .get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Future<List<QueueEntry>> getAll() async {
    final snapshot = await _col.orderBy('createdAt').get();
    return snapshot.docs.map(_fromDoc).toList();
  }

  QueueEntry _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final createdAt = d['createdAt'];
    DateTime created;
    if (createdAt is Timestamp) {
      created = createdAt.toDate();
    } else {
      created = DateTime.now();
    }
    final est = d['estimatedTime'];
    DateTime? estimated;
    if (est is Timestamp) {
      estimated = est.toDate();
    }
    return QueueEntry(
      id: doc.id,
      clientId: d['clientId'] as String,
      position: (d['position'] as num?)?.toInt() ?? 0,
      estimatedTime: estimated,
      createdAt: created,
    );
  }
}
