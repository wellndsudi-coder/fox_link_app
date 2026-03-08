import 'package:fox_link_app/core/auth/auth_api.dart';
import 'package:fox_link_app/core/auth/token_response.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Auth API implementation. Uses Firebase Auth for credentials, then returns
/// mock tokens for the token layer (access 1h, refresh 30 days).
/// Replace with real backend API when available.
class AuthApiImpl implements AuthApi {
  final FirebaseAuth _firebaseAuth;

  AuthApiImpl({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Future<TokenResponse> login(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = _firebaseAuth.currentUser;
      if (user == null) throw AuthException('Login failed');

      return TokenResponse(
        accessToken: _generateMockToken(user.uid, expiresIn: 3600),
        refreshToken: _generateMockToken(user.uid, expiresIn: 30 * 24 * 3600),
        expiresIn: 3600,
        uid: user.uid,
        email: user.email,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw AuthException('E-mail ou senha inválidos.');
      }
      throw AuthException(e.message ?? 'Erro ao fazer login.');
    }
  }

  @override
  Future<TokenResponse> refresh(String refreshToken) async {
    if (refreshToken.isEmpty) throw AuthException('Refresh token inválido');
    final uid = _parseUidFromMockToken(refreshToken);
    if (uid == null) throw AuthException('Refresh token inválido');

    return TokenResponse(
      accessToken: _generateMockToken(uid, expiresIn: 3600),
      refreshToken: _generateMockToken(uid, expiresIn: 30 * 24 * 3600),
      expiresIn: 3600,
    );
  }

  String _generateMockToken(String uid, {required int expiresIn}) {
    final exp = DateTime.now().add(Duration(seconds: expiresIn)).millisecondsSinceEpoch ~/ 1000;
    return 'mock_${uid}_$exp';
  }

  String? _parseUidFromMockToken(String token) {
    final parts = token.split('_');
    if (parts.length >= 3 && parts[0] == 'mock') return parts[1];
    return null;
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
