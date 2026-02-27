import 'package:fox_link_app/modules/auth/domain/repositories/auth_repository.dart';
import 'package:fox_link_app/modules/auth/domain/repositories/invite_repository.dart';
import 'package:fox_link_app/modules/users/infra/datasources/user_remote_datasource.dart';

class RegisterUserUseCase {

  final AuthRepository authRepository;
  final InviteRepository inviteRepository;
  final UserRemoteDataSource userRemote;

  RegisterUserUseCase({
    required this.authRepository,
    required this.inviteRepository,
    required this.userRemote,
  });

  Future<RegisterResult> execute({
    required String email,
    required String password,
  }) async {

    final invite =
    await inviteRepository.getInviteByEmail(email);

    final user =
    await authRepository.register(email, password);

    if (invite != null) {

      await userRemote.createUser(
        uid: user.uid,
        email: email,
        role: invite.role,
        tenantId: invite.tenantId,
      );

      await inviteRepository.deleteInvite(email);

      return RegisterResult(
        uid: user.uid,
        email: email,
        tenantId: invite.tenantId,
        role: invite.role,
        isProfessional: true,
      );
    }

    // Novo salão (admin)
    return RegisterResult(
      uid: user.uid,
      email: email,
      isProfessional: false,
    );
  }
}

class RegisterResult {
  final String uid;
  final String email;
  final String? tenantId;
  final String? role;
  final bool isProfessional;

  RegisterResult({
    required this.uid,
    required this.email,
    this.tenantId,
    this.role,
    required this.isProfessional,
  });
}