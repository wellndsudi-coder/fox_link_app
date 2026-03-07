import 'package:fox_link_app/modules/auth/domain/entities/onboarding_data.dart';
import 'package:fox_link_app/modules/auth/domain/repositories/auth_repository.dart';
import 'package:fox_link_app/modules/auth/domain/repositories/invite_repository.dart';
import 'package:fox_link_app/modules/users/infra/datasources/user_remote_datasource.dart';
import 'package:fox_link_app/modules/professionals/infra/datasources/professional_remote_datasource.dart';

class RegisterUserUseCase {
  final AuthRepository authRepository;
  final InviteRepository inviteRepository;
  final UserRemoteDataSource userRemote;
  final ProfessionalRemoteDataSource professionalRemote;

  RegisterUserUseCase({
    required this.authRepository,
    required this.inviteRepository,
    required this.userRemote,
    required this.professionalRemote,
  });

  Future<RegisterResult> execute({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    final invite = await inviteRepository.getInviteByEmail(email);
    final user = await authRepository.register(email, password);

    if (invite != null) {
      await userRemote.createUser(
        uid: user.uid,
        email: email,
        role: invite.role,
        tenantId: invite.tenantId,
        name: invite.name,
      );

      final professionalId = await professionalRemote.linkUidToProfessionalByEmailInTenant(
        tenantId: invite.tenantId,
        email: email,
        uid: user.uid,
      );

      await inviteRepository.deleteInvite(email);

      return RegisterResult(
        uid: user.uid,
        email: email,
        tenantId: invite.tenantId,
        role: invite.role,
        professionalId: professionalId,
        isProfessional: true,
      );
    }

    await userRemote.saveOnboardingProfile(
      uid: user.uid,
      email: email,
      name: name,
      phone: phone,
    );

    return RegisterResult(
      uid: user.uid,
      email: email,
      isProfessional: false,
      onboardingData: OnboardingData(
        uid: user.uid,
        name: name,
        email: email,
        phone: phone,
      ),
    );
  }
}

class RegisterResult {
  final String uid;
  final String email;
  final String? tenantId;
  final String? role;
  final String? professionalId;
  final bool isProfessional;
  final OnboardingData? onboardingData;

  RegisterResult({
    required this.uid,
    required this.email,
    this.tenantId,
    this.role,
    this.professionalId,
    required this.isProfessional,
    this.onboardingData,
  });
}
