import 'package:cloud_firestore/cloud_firestore.dart';

class UserRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Salva dados do usuário em onboarding (sem tenantId/role).
  Future<void> saveOnboardingProfile({
    required String uid,
    required String email,
    required String name,
    required String phone,
  }) async {
    await _firestore.collection('users').doc(uid).set(
      {
        'uid': uid,
        'email': email,
        'name': name,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Cria ou atualiza usuário completo (com role/roles e tenantId).
  /// roles: array de papéis (ex: ['owner','professional']). Se fornecido, também grava role para compatibilidade.
  Future<void> createUser({
    required String uid,
    required String email,
    required String role,
    required String tenantId,
    String? name,
    String? phone,
    List<String>? roles,
  }) async {
    final rolesList = roles ?? [role];
    final data = <String, dynamic>{
      'uid': uid,
      'email': email,
      'role': role,
      'roles': rolesList,
      'tenantId': tenantId,
      'name': name ?? email.split('@').first,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (phone != null) data['phone'] = phone;
    await _firestore.collection('users').doc(uid).set(
      data,
      SetOptions(merge: true),
    );
  }

  /// 🔹 Busca dados do usuário
  Future<Map<String, dynamic>> getUser(String uid) async {
    final doc =
    await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) {
      throw Exception('Usuário não encontrado no Firestore');
    }

    return doc.data()!;
  }

  /// 🔹 Atualiza apenas alguns campos
  Future<void> updateUser({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  /// 🔹 Atualiza nome do usuário (helper)
  Future<void> updateUserName({
    required String uid,
    required String name,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'name': name,
    });
  }

  /// 🔹 Deleta usuário (caso precise no futuro)
  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }
}