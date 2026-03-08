import 'package:fox_link_app/core/auth/auth_api.dart';
import 'package:fox_link_app/core/auth/auth_state.dart';
import 'package:fox_link_app/core/auth/token_manager.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/auth/infra/datasources/auth_remote_datasource.dart';

/// Manages session lifecycle: validation, token refresh, logout.
class SessionManager {
  final TokenManager _tokenManager;
  final AuthApi _authApi;
  final TenantSession _tenantSession;
  final AuthState _authState;
  final AuthRemoteDataSource _authRemote;

  SessionManager({
    required TokenManager tokenManager,
    required AuthApi authApi,
    required TenantSession tenantSession,
    required AuthState authState,
    required AuthRemoteDataSource authRemote,
  })  : _tokenManager = tokenManager,
        _authApi = authApi,
        _tenantSession = tenantSession,
        _authState = authState,
        _authRemote = authRemote;

  bool get isLoggedIn => _authState.isAuthenticated;

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
    if (data.tenantId != null && data.uid != null && data.email != null && data.roles.isNotEmpty) {
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
