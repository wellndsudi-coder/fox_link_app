import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/core/config/plan_config.dart';
import 'package:fox_link_app/core/database/tenant_firestore.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/injection/injection.dart';

class ProfessionalRemoteDataSource {

  final TenantFirestore firestore =
  getIt<TenantFirestore>();

  final FirebaseFirestore rootFirestore =
  getIt<FirebaseFirestore>();

  final TenantSession session =
  getIt<TenantSession>();

  // ==========================================================
  // 🔹 Contar profissionais do tenant
  // ==========================================================
  Future<int> getCurrentCount() async {
    final snapshot = await firestore
        .collection('professionals')
        .get();

    return snapshot.docs.length;
  }

  // ==========================================================
  // 🔹 Buscar plano do tenant
  // ==========================================================
  Future<String> getCurrentPlan() async {
    final tenantDoc = await rootFirestore
        .collection('tenants')
        .doc(session.tenantId)
        .get();

    return tenantDoc['plan'];
  }

  // ==========================================================
  // 🔹 Criar profissional (convite)
  // 🔥 VOLTAMOS ao padrão correto (sem uid aqui)
  // ==========================================================
  Future<void> createProfessional({
    required String name,
    required String email,
  }) async {

    final plan = await getCurrentPlan();
    final count = await getCurrentCount();

    if (count >= PlanConfig.maxProfessionals(plan)) {
      throw Exception(
          "Limite de profissionais do plano atingido.");
    }

    final pendingDoc = await rootFirestore
        .collection('users_pending')
        .doc(email)
        .get();

    if (pendingDoc.exists) {
      throw Exception(
          "Já existe um convite para este email.");
    }

    await firestore
        .collection('professionals')
        .add({
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await rootFirestore
        .collection('users_pending')
        .doc(email)
        .set({
      'tenantId': session.tenantId,
      'role': 'professional',
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // 🔥 NOVO: Vincular UID após cadastro do profissional
  // ==========================================================
  Future<String?> linkUidToProfessionalByEmail({
    required String email,
    required String uid,
  }) async {

    final snapshot = await firestore
        .collection('professionals')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;

    await firestore
        .collection('professionals')
        .doc(doc.id)
        .update({
      'uid': uid,
    });

    return doc.id; // retorna professionalId
  }

  // ==========================================================
  // 🔹 Buscar profissional pelo UID
  // ==========================================================
  Future<Map<String, dynamic>?> getProfessionalByUid(String uid) async {

    final snapshot = await firestore
        .collection('professionals')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;

    return {
      'id': doc.id,
      ...doc.data(),
    };
  }

  // ==========================================================
  // 🔹 Listar profissionais
  // ==========================================================
  Future<List<Map<String, dynamic>>> getProfessionals() async {

    final snapshot =
    await firestore.collection('professionals').get();

    return snapshot.docs
        .map((doc) => {
      'id': doc.id,
      ...doc.data(),
    })
        .toList();
  }

  // ==========================================================
  // 🔹 Stream para admin
  // ==========================================================
  Stream<QuerySnapshot<Map<String, dynamic>>> streamProfessionals() {
    return firestore
        .collection('professionals')
        .snapshots();
  }

  // ==========================================================
  // 🔹 Deletar profissional
  // ==========================================================
  Future<void> deleteProfessional(String id) async {
    await firestore
        .collection('professionals')
        .doc(id)
        .delete();
  }
}