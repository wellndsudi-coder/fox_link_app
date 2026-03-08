import 'package:fox_link_app/core/auth/token_response.dart';

/// Abstract interface for authentication API (login, refresh).
abstract class AuthApi {
  Future<TokenResponse> login(String email, String password);
  Future<TokenResponse> refresh(String refreshToken);
}
