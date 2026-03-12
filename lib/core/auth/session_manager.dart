import 'package:fox_link_app/core/auth/auth_api.dart';
import 'package:fox_link_app/core/auth/auth_state.dart';
import 'package:fox_link_app/core/auth/token_manager.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/auth/infra/datasources/auth_remote_datasource.dart';
import 'package:fox_link_app/modules/professionals/infra/datasources/professional_remote_datasource.dart';
import 'package:fox_link_app/modules/tenant/infra/datasources/tenant_remote_datasource.dart';
import 'package:fox_link_app/modules/users/infra/datasources/user_remote_datasource.dart';

/// Manages session lifecycle: validation, token refresh, logout.
class SessionManager {
  final TokenManager _tokenManager;
  final AuthApi _authApi;
  final TenantSession _tenantSession;
  final AuthState _authState;
  final AuthRemoteDataSource _authRemote;
  final UserRemoteDataSource _userRemote;
  final TenantRemoteDataSource _tenantRemote;
  final ProfessionalRemoteDataSource _professionalRemote;

  SessionManager({
    required TokenManager tokenManager,
    required AuthApi authApi,
    required TenantSession tenantSession,
    required AuthState authState,
    required AuthRemoteDataSource authRemote,
    required UserRemoteDataSource userRemote,
    required TenantRemoteDataSource tenantRemote,
    required ProfessionalRemoteDataSource professionalRemote,
  })  : _tokenManager = tokenManager,
        _authApi = authApi,
        _tenantSession = tenantSession,
        _authState = authState,
        _authRemote = authRemote,
        _userRemote = userRemote,
        _tenantRemote = tenantRemote,
        _professionalRemote = professionalRemote;

  bool get isLoggedIn => _authState.isAuthenticated;

  /// Valida sessão na web usando Firebase Auth + Firestore (sem FlutterSecureStorage).
  /// Retorna true se o usuário está logado e a sessão foi restaurada.
  Future<bool> validateSessionForWeb() async {
    final user = _authRemote.currentUser;
    if (user == null || user.uid.isEmpty) return false;

    try {
      final userData = await _userRemote.getUser(user.uid);
      final tenantId = userData['tenantId'] as String?;
      final rolesRaw = userData['roles'];
      final roleSingle = userData['role'] as String?;

      if (tenantId == null || tenantId.isEmpty) return false;

      final roles = rolesRaw != null
          ? List<String>.from(rolesRaw as List)
          : (roleSingle != null ? [roleSingle] : <String>[]);
      if (roles.isEmpty) return false;

      final tenantSnapshot = await _tenantRemote.getTenant(tenantId);
      final tenantData = tenantSnapshot.data();
      if (tenantData == null) return false;

      final status = tenantData['status'] ?? 'active';
      if (status != 'active') return false;

      _tenantSession.setSessionWithRoles(
        tenantId: tenantId,
        roles: roles,
        uid: user.uid,
        email: user.email ?? '',
      );

      if (roles.contains('professional')) {
        final prof = await _professionalRemote.getProfessionalByUid(user.uid);
        if (prof?['id'] != null) {
          _tenantSession.setProfessionalId(prof!['id'] as String);
        }
      }

      _authState.setAuthenticated();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Validates session: no tokens -> unauthenticated; access valid -> authenticated;
  /// access expired -> try refresh -> save new tokens -> authenticated; else -> logout.
  Future<bool> validateSession() async {
    if (!await _tokenManager.hasTokens()) {
      _authState.setUnauthenticated();
      return false;
    }

    final expired = await _tokenManager.isAccessExpired();
    if (!expired) {
      await _restoreTenantSession();
      _authState.setAuthenticated();
      return true;
    }

    final refreshToken = await _tokenManager.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _performLogout();
      return false;
    }

    try {
      final response = await _authApi.refresh(refreshToken);
      await _tokenManager.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        expiresInSeconds: response.expiresIn,
      );
      await _restoreTenantSession();
      _authState.setAuthenticated();
      return true;
    } catch (_) {
      await _performLogout();
      return false;
    }
  }

  Future<void> _restoreTenantSession() async {
    final data = await _tokenManager.loadSessionData();
    if (data.uid == null || data.email == null || data.roles.isEmpty) return;

    // Usa Firestore como fonte da verdade para tenantId e roles
    // (evita dados desatualizados ou corrompidos no armazenamento local)
    try {
      final userData = await _userRemote.getUser(data.uid!);
      final tenantId = userData['tenantId'] as String?;
      final rolesRaw = userData['roles'];
      final roleSingle = userData['role'] as String?;

      if (tenantId == null || tenantId.isEmpty) return;

      final roles = rolesRaw != null
          ? List<String>.from(rolesRaw as List)
          : (roleSingle != null ? [roleSingle] : <String>[]);
      if (roles.isEmpty) return;

      _tenantSession.setSessionWithRoles(
        tenantId: tenantId,
        roles: roles,
        uid: data.uid!,
        email: data.email!,
      );
      final professionalId = userData['professionalId'] as String? ?? data.professionalId;
      if (professionalId != null && professionalId.isNotEmpty) {
        _tenantSession.setProfessionalId(professionalId);
      }

      // Atualiza cache com dados corretos do Firestore
      await _tokenManager.saveSessionData(
        tenantId: tenantId,
        uid: data.uid!,
        email: data.email!,
        roles: roles,
        professionalId: professionalId,
      );
    } catch (_) {
      // Fallback: usa dados do cache se Firestore falhar (offline)
      if (data.tenantId != null && data.tenantId!.isNotEmpty) {
        _tenantSession.setSessionWithRoles(
          tenantId: data.tenantId!,
          roles: data.roles,
          uid: data.uid!,
          email: data.email!,
        );
        if (data.professionalId != null) {
          _tenantSession.setProfessionalId(data.professionalId!);
        }
      }
    }
  }

  /// Attempts to refresh the access token. Returns new access token or null on failure.
  Future<String?> refreshToken() async {
    final refreshToken = await _tokenManager.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final response = await _authApi.refresh(refreshToken);
      await _tokenManager.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        expiresInSeconds: response.expiresIn,
      );
      return response.accessToken;
    } catch (_) {
      await _performLogout();
      return null;
    }
  }

  Future<void> logout() => _performLogout();

  Future<void> _performLogout() async {
    await _tokenManager.clearTokens();
    _tenantSession.clear();
    await _authRemote.signOut();
    _authState.setUnauthenticated();
  }
}
