import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Salva o token FCM do dispositivo em users/{uid} para permitir
/// notificações push (ex: reagendamento solicitado pelo profissional).
class FcmTokenService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Solicita permissão, obtém o token e salva em users/{uid}.
  Future<void> registerToken(String uid) async {
    final settings = await _messaging.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return;
    }

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await _firestore.collection('users').doc(uid).set(
      {'fcmToken': token, 'fcmTokenUpdatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  /// Remove o token ao fazer logout (opcional).
  Future<void> clearToken(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'fcmToken': FieldValue.delete(),
      'fcmTokenUpdatedAt': FieldValue.delete(),
    });
  }
}
