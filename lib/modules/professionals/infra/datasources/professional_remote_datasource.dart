import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/core/config/plan_config.dart';
import 'package:fox_link_app/core/database/tenant_firestore.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/modules/subscription/domain/usecases/check_trial_expired_usecase.dart';

class ProfessionalRemoteDataSource {

  final TenantFirestore firestore =
  getIt<TenantFirestore>();

  final FirebaseFirestore rootFirestore =
  getIt<FirebaseFirestore>();

  final TenantSession session =
  getIt<TenantSession>();

  CheckTrialExpiredUseCase get _checkTrialExpired =>
      getIt<CheckTrialExpiredUseCase>();

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
    final tenantId = session.tenantId;
    if (tenantId == null) return PlanConfig.trial;
    final tenantDoc = await rootFirestore
        .collection('tenants')
        .doc(tenantId)
        .get();

    return tenantDoc['plan'] as String? ?? PlanConfig.trial;
  }

  // ==========================================================
  // 🔹 Criar profissional (convite)
  // 🔥 VOLTAMOS ao padrão correto (sem uid aqui)
  // ==========================================================
  Future<void> createProfessional({
    required String name,
    required String email,
  }) async {
    final tenantId = session.tenantId;
    if (tenantId != null) {
      final expired = await _checkTrialExpired(tenantId);
      if (expired) {
        throw Exception(
            'Seu período de teste expirou. Escolha um plano para continuar.',
        );
      }
    }

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
  // Cria profissional com UID já definido (owner que também atende)
  // Não usa users_pending - usuário já está autenticado
  // ==========================================================
  Future<String> createProfessionalAsOwner({
    required String tenantId,
    required String uid,
    required String name,
    required String email,
  }) async {
    final expired = await _checkTrialExpired(tenantId);
    if (expired) {
      throw Exception(
          'Seu período de teste expirou. Escolha um plano para continuar.',
      );
    }

    final tenantDoc = await rootFirestore
        .collection('tenants')
        .doc(tenantId)
        .get();
    final plan = tenantDoc['plan'] as String? ?? PlanConfig.trial;

    final countSnapshot = await rootFirestore
        .collection('tenants')
        .doc(tenantId)
        .collection('professionals')
        .get();
    final count = countSnapshot.docs.length;

    if (count >= PlanConfig.maxProfessionals(plan)) {
      throw Exception(
          'Seu plano não permite adicionar mais profissionais.',
      );
    }

    final ref = await rootFirestore
        .collection('tenants')
        .doc(tenantId)
        .collection('professionals')
        .add({
      'name': name,
      'email': email,
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  // ==========================================================
  // Vincular UID após cadastro do profissional
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