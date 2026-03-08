import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fox_link_app/core/database/tenant_firestore.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/entities/favorite_professional.dart';

abstract class FavoritesRemoteDataSource {
  Future<void> add({
    required String clientId,
    required String professionalId,
    required String professionalName,
  });

  Future<void> remove({
    required String clientId,
    required String professionalId,
  });

  Future<List<FavoriteProfessional>> getByClient(String clientId);

  Future<bool> isFavorite({
    required String clientId,
    required String professionalId,
  });
}

class FavoritesRemoteDataSourceImpl implements FavoritesRemoteDataSource {
  final TenantFirestore firestore;

  FavoritesRemoteDataSourceImpl(this.firestore);

  CollectionReference<Map<String, dynamic>> _favoritesCol(String clientId) =>
      firestore.collection('clients').doc(clientId).collection('favorites');

  @override
  Future<void> add({
    required String clientId,
    required String professionalId,
    required String professionalName,
  }) async {
    await _favoritesCol(clientId).doc(professionalId).set({
      'professionalId': professionalId,
      'professionalName': professionalName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> remove({
    required String clientId,
    required String professionalId,
  }) async {
    await _favoritesCol(clientId).doc(professionalId).delete();
  }

  @override
  Future<List<FavoriteProfessional>> getByClient(String clientId) async {
    final snapshot = await _favoritesCol(clientId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map(_fromDoc).toList();
  }

  @override
  Future<bool> isFavorite({
    required String clientId,
    required String professionalId,
  }) async {
    final doc = await _favoritesCol(clientId).doc(professionalId).get();
    return doc.exists;
  }

  FavoriteProfessional _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final createdAt = d['createdAt'];
    DateTime created;
    if (createdAt is Timestamp) {
      created = createdAt.toDate();
    } else {
      created = DateTime.now();
    }
    return FavoriteProfessional(
      professionalId: d['professionalId'] as String? ?? doc.id,
      professionalName: d['professionalName'] as String? ?? 'Profissional',
      createdAt: created,
    );
  }
}
