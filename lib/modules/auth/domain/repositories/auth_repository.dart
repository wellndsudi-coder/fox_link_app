import 'package:fox_link_app/modules/auth/domain/entities/auth_user.dart';

abstract class AuthRepository {
  Future<AuthUser> signIn(String email, String password);
  Future<AuthUser> register(String email, String password);
  Future<void> signOut();
}