import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class TenantRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 🏢 Criar novo salão (Admin)
  Future<String> createTenant({
    required String name,
    required String ownerId,
  }) async {
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 7));

    final doc = await _firestore.collection('tenants').add({
      'name': name,
      'ownerId': ownerId,
      'plan': 'trial',
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'logoUrl': null,
    });

    return doc.id;
  }

  /// 🖼 Upload de logo do salão
  Future<void> uploadLogo({
    required String tenantId,
    required File file,
  }) async {
    final ref = _storage.ref().child('tenants/$tenantId/logo.jpg');

    await ref.putFile(file);

    final url = await ref.getDownloadURL();

    await _firestore.collection('tenants').doc(tenantId).update({
      'logoUrl': url,
    });
  }

  /// 🔍 Buscar salão específico
  Future<DocumentSnapshot<Map<String, dynamic>>> getTenant(
      String tenantId) {
    return _firestore
        .collection('tenants')
        .doc(tenantId)
        .get();
  }

  /// 📋 Listar todos os salões ativos (para cliente escolher)
  Future<List<Map<String, dynamic>>> getAllTenants() async {
    final snapshot = await _firestore
        .collection('tenants')
        .where('status', isEqualTo: 'active')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'name': data['name'] ?? '',
        'logoUrl': data['logoUrl'],
      };
    }).toList();
  }

  /// 🔎 Buscar salão por nome (futuro – busca inteligente)
  Future<List<Map<String, dynamic>>> searchTenantsByName(
      String query) async {
    final snapshot = await _firestore
        .collection('tenants')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'name': data['name'] ?? '',
        'logoUrl': data['logoUrl'],
      };
    }).toList();
  }
}