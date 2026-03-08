import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _accessTokenKey = 'access_token';
const _refreshTokenKey = 'refresh_token';
const _accessExpiresAtKey = 'access_expires_at';
const _sessionTenantIdKey = 'session_tenant_id';
const _sessionUidKey = 'session_uid';
const _sessionEmailKey = 'session_email';
const _sessionRolesKey = 'session_roles';
const _sessionProfessionalIdKey = 'session_professional_id';
const _expiryBufferSeconds = 60;

/// Manages secure storage of access and refresh tokens.
class TokenManager {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresInSeconds,
    bool persistRefreshToken = true,
  }) async {
    final expiresAt = DateTime.now().add(Duration(seconds: expiresInSeconds));
    final writes = <Future<void>>[
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _accessExpiresAtKey, value: expiresAt.toIso8601String()),
    ];
    if (persistRefreshToken) {
      writes.add(_storage.write(key: _refreshTokenKey, value: refreshToken));
    } else {
      writes.add(_storage.delete(key: _refreshTokenKey));
    }
    await Future.wait(writes);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<bool> isAccessExpired() async {
    final expiresAtStr = await _storage.read(key: _accessExpiresAtKey);
    if (expiresAtStr == null) return true;
    final expiresAt = DateTime.tryParse(expiresAtStr);
    if (expiresAt == null) return true;
    return DateTime.now().add(const Duration(seconds: _expiryBufferSeconds)).isAfter(expiresAt);
  }

  Future<bool> hasTokens() async {
    final access = await getAccessToken();
    final refresh = await getRefreshToken();
    return (access != null && access.isNotEmpty) || (refresh != null && refresh.isNotEmpty);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _accessExpiresAtKey),
      _storage.delete(key: _sessionTenantIdKey),
      _storage.delete(key: _sessionUidKey),
      _storage.delete(key: _sessionEmailKey),
      _storage.delete(key: _sessionRolesKey),
      _storage.delete(key: _sessionProfessionalIdKey),
    ]);
  }

  Future<void> saveSessionData({
    required String tenantId,
    required String uid,
    required String email,
    required List<String> roles,
    String? professionalId,
  }) async {
    await Future.wait([
      _storage.write(key: _sessionTenantIdKey, value: tenantId),
      _storage.write(key: _sessionUidKey, value: uid),
      _storage.write(key: _sessionEmailKey, value: email),
      _storage.write(key: _sessionRolesKey, value: roles.join(',')),
      if (professionalId != null)
        _storage.write(key: _sessionProfessionalIdKey, value: professionalId),
    ]);
  }

  Future<({String? tenantId, String? uid, String? email, List<String> roles, String? professionalId})> loadSessionData() async {
    final tenantId = await _storage.read(key: _sessionTenantIdKey);
    final uid = await _storage.read(key: _sessionUidKey);
    final email = await _storage.read(key: _sessionEmailKey);
    final rolesStr = await _storage.read(key: _sessionRolesKey);
    final professionalId = await _storage.read(key: _sessionProfessionalIdKey);
    final roles = rolesStr != null && rolesStr.isNotEmpty
        ? rolesStr.split(',').where((s) => s.isNotEmpty).toList()
        : <String>[];
    return (tenantId: tenantId, uid: uid, email: email, roles: roles, professionalId: professionalId);
  }
}
