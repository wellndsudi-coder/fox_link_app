import 'package:fox_link_app/modules/auth/domain/entities/auth_user.dart';
import 'package:fox_link_app/modules/auth/domain/repositories/auth_repository.dart';
import 'package:fox_link_app/modules/auth/infra/datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;

  AuthRepositoryImpl(this.remote);

  @override
  Future<AuthUser> signIn(String email, String password) async {
    final result = await remote.signIn(
      email: email,
      password: password,
    );

    final user = result.user;

    if (user == null) {
      throw Exception('Falha ao realizar login.');
    }

    return AuthUser(
      uid: user.uid,
      email: user.email ?? '',
    );
  }

  @override
  Future<AuthUser> register(String email, String password) async {
    final result = await remote.register(
      email: email,
      password: password,
    );

    final user = result.user;

    if (user == null) {
      throw Exception('Falha ao criar conta.');
    }

    // 🔥 IMPORTANTE:
    // NÃO criar documento no Firestore aqui.
    // A criação do usuário no banco deve acontecer
    // via UseCase específico (Admin, Profissional ou Cliente).

    return AuthUser(
      uid: user.uid,
      email: user.email ?? '',
    );
  }

  @override
  Future<void> signOut() async {
    await remote.signOut();
  }
}