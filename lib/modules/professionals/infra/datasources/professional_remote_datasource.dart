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
  // 🔹 Criar profissional (100% dentro do tenant)
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
  // 🔹 Listar profissionais (Cliente usa isso)
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