import 'package:fox_link_app/core/auth/auth_api.dart';
import 'package:fox_link_app/core/auth/token_manager.dart';
import 'package:fox_link_app/features/login/domain/remember_me_preference.dart';

/// Orchestrates login: calls AuthApi, saves tokens with Remember Me preference.
class LoginUseCase {
  final AuthApi _authApi;
  final TokenManager _tokenManager;
  final RememberMePreference _rememberMePreference;

  LoginUseCase({
    required AuthApi authApi,
    required TokenManager tokenManager,
    required RememberMePreference rememberMePreference,
  })  : _authApi = authApi,
        _tokenManager = tokenManager,
        _rememberMePreference = rememberMePreference;

  Future<void> saveRememberMe(bool value) => _rememberMePreference.set(value);

  Future<bool> getRememberMe() => _rememberMePreference.get();

  /// Performs login and saves tokens. Returns (uid, email) for downstream flow.
  /// Throws AuthException on invalid credentials.
  Future<({String uid, String email})> execute(String email, String password) async {
    final response = await _authApi.login(email, password);
    final rememberMe = await _rememberMePreference.get();
    await _tokenManager.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      expiresInSeconds: response.expiresIn,
      persistRefreshToken: rememberMe,
    );
    return (uid: response.uid ?? '', email: response.email ?? email);
  }
}
