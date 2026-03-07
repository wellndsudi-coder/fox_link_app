import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fox_link_app/core/config/plan_config.dart';
import 'dart:io';

class TenantRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  Future<String> createTenant({
    required String name,
    required String ownerId,
    String? logoUrl,
    String? address,
    String? city,
  }) async {
    final doc = _firestore.collection('tenants').doc();
    final inviteCode = _generateInviteCode();
    final now = DateTime.now();
    final expireDate = now.add(Duration(days: PlanConfig.trialDays(PlanConfig.trial)));

    await doc.set({
      'name': name,
      'ownerId': ownerId,
      'status': 'active',
      'logoUrl': logoUrl,
      'address': address,
      'city': city,
      'inviteCode': inviteCode,
      'createdAt': now,
      'plan': PlanConfig.trial,
      'planStartDate': now,
      'planExpireDate': expireDate,
      'isTrial': true,
      'expiresAt': expireDate,
    });

    return doc.id;
  }

  String _generateInviteCode() {
    final r = Random();
    return List.generate(6, (_) => _chars[r.nextInt(_chars.length)]).join();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> getTenantByInviteCode(
      String code) async {
    final snapshot = await _firestore
        .collection('tenants')
        .where('inviteCode', isEqualTo: code.toUpperCase())
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first;
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

  Future<void> updateTenantConfig({
    required String tenantId,
    String? name,
    String? logoUrl,
    String? primaryColor,
    String? secondaryColor,
    String? accentColor,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (logoUrl != null) updates['logoUrl'] = logoUrl;
    if (primaryColor != null) updates['primaryColor'] = primaryColor;
    if (secondaryColor != null) updates['secondaryColor'] = secondaryColor;
    if (accentColor != null) updates['accentColor'] = accentColor;
    if (updates.isEmpty) return;
    await _firestore.collection('tenants').doc(tenantId).update(updates);
  }

  Future<void> updatePlan({
    required String tenantId,
    required String plan,
  }) async {
    final isTrial = plan == PlanConfig.trial;
    final trialDaysCount = PlanConfig.trialDays(plan);
    final now = DateTime.now();
    final expireDate = trialDaysCount > 0
        ? now.add(Duration(days: trialDaysCount))
        : null;

    await _firestore.collection('tenants').doc(tenantId).update({
      'plan': plan,
      'planStartDate': now,
      'planExpireDate': expireDate,
      'isTrial': isTrial,
      'expiresAt': expireDate,
    });
  }
}