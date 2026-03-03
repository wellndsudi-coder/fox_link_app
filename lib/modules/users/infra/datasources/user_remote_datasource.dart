import 'package:cloud_firestore/cloud_firestore.dart';

class UserRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Cria ou sobrescreve completamente o usuário
  /// Usado no fluxo multi-tenant (primeiro cadastro vira admin ou profissional)
  Future<void> createUser({
    required String uid,
    required String email,
    required String role,
    required String tenantId,
    String? name, // 🔥 NOVO CAMPO
  }) async {
    await _firestore.collection('users').doc(uid).set(
      {
        'uid': uid,
        'email': email,
        'role': role,
        'tenantId': tenantId,
        'name': name ?? email.split('@').first, // 🔥 fallback inteligente
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: false),
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