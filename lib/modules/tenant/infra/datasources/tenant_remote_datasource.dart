import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class TenantRemoteDataSource {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createTenant({
    required String name,
    required String ownerId,
    String? logoUrl,
  }) async {

    final doc = _firestore.collection('tenants').doc();

    await doc.set({
      'name': name,
      'ownerId': ownerId,
      'status': 'active',
      'logoUrl': logoUrl,
      'createdAt': DateTime.now(),
    });

    return doc.id;
  }

  Future<String> uploadLogo({
    required String tenantId,
    required File file,
  }) async {

    final ref = FirebaseStorage.instance
        .ref()
        .child('tenants/$tenantId/logo.jpg');

    await ref.putFile(file);

    return await ref.getDownloadURL();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getTenant(
      String tenantId) {
    return _firestore
        .collection('tenants')
        .doc(tenantId)
        .get();
  }
}