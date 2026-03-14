import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/core/widgets/auth_welcome_layout.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/core/auth/auth_state.dart';
import 'package:fox_link_app/core/auth/token_manager.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/auth/infra/auth_api_impl.dart';
import 'package:fox_link_app/features/login/domain/login_use_case.dart';
import 'package:fox_link_app/modules/auth/domain/entities/invite_entity.dart';
import 'package:fox_link_app/modules/auth/domain/entities/onboarding_data.dart';
import 'package:fox_link_app/modules/auth/domain/repositories/invite_repository.dart';
import 'package:fox_link_app/modules/users/infra/datasources/user_remote_datasource.dart';
import 'package:fox_link_app/modules/tenant/infra/datasources/tenant_remote_datasource.dart';
import 'package:fox_link_app/modules/professionals/infra/datasources/professional_remote_datasource.dart';
import 'package:fox_link_app/core/white_label/white_label_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final LoginUseCase _loginUseCase;
  late final TokenManager _tokenManager;
  late final AuthState _authState;
  late final TenantSession _tenantSession;
  late final UserRemoteDataSource _userRemote;
  late final TenantRemoteDataSource _tenantRemote;
  late final ProfessionalRemoteDataSource _professionalRemote;
  late final InviteRepository _inviteRepository;
  late final WhiteLabelService _whiteLabel;

  bool _showPassword = false;
  bool _isLoading = false;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _loginUseCase = getIt<LoginUseCase>();
    _tokenManager = getIt<TokenManager>();
    _authState = getIt<AuthState>();
    _tenantSession = getIt<TenantSession>();
    _userRemote = getIt<UserRemoteDataSource>();
    _tenantRemote = getIt<TenantRemoteDataSource>();
    _professionalRemote = getIt<ProfessionalRemoteDataSource>();
    _inviteRepository = getIt<InviteRepository>();
    _whiteLabel = getIt<WhiteLabelService>();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final value = await _loginUseCase.getRememberMe();
    if (mounted) setState(() => _rememberMe = value);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      await _loginUseCase.saveRememberMe(_rememberMe);
      final result = await _loginUseCase.execute(email, _passwordController.text.trim());

      final uid = result.uid;
      final userEmail = result.email;
      if (uid.isEmpty) throw AuthException('Erro ao obter dados do usuário.');

      final invite = await _inviteRepository.getInviteByEmail(email);
      if (invite != null) {
        await _processInvite(invite: invite, uid: uid, email: userEmail);
        return;
      }

      final userData = await _userRemote.getUser(uid);
      final tenantId = userData['tenantId'] as String?;
      final rolesRaw = userData['roles'];
      final roleSingle = userData['role'] as String?;
      final roles = rolesRaw != null
          ? List<String>.from(rolesRaw as List)
          : (roleSingle != null ? [roleSingle] : <String>[]);

      // Master/Super Admin: pode acessar sem tenantId
      if (roles.contains('master') || roles.contains('super_admin')) {
        _tenantSession.setSessionWithRoles(
          tenantId: tenantId ?? '',
          roles: roles,
          uid: uid,
          email: userEmail,
        );
        await _tokenManager.saveSessionData(
          tenantId: tenantId ?? '',
          uid: uid,
          email: userEmail,
          roles: roles,
        );
        _authState.setAuthenticated();
        if (!mounted) return;
        context.go('/master');
        return;
      }

      // Perfil incompleto: criou conta mas não completou "Criar salão"
      if (tenantId == null || roles.isEmpty) {
        final emailStr = userData['email'] as String? ?? userEmail;
        final name = userData['name'] as String? ?? emailStr.split('@').first;
        final phone = userData['phone'] as String? ?? '';
        _authState.setAuthenticated();
        if (!mounted) return;
        context.go('/onboarding', extra: OnboardingData(
          uid: uid,
          email: emailStr,
          name: name,
          phone: phone,
        ));
        return;
      }

      final tenantSnapshot = await _tenantRemote.getTenant(tenantId);
      final tenantData = tenantSnapshot.data();
      if (tenantData == null) throw Exception('Tenant não encontrado.');

      final status = tenantData['status'] ?? 'active';
      if (status != 'active') throw Exception('Seu salão está suspenso.');

      DateTime? expiresAt;
      if (tenantData['expiresAt'] != null) {
        expiresAt = (tenantData['expiresAt'] as Timestamp).toDate();
      }
      if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
        _tenantSession.setSessionWithRoles(
          tenantId: userData['tenantId'] as String,
          roles: roles,
          uid: uid,
          email: userEmail,
        );
        await _tokenManager.saveSessionData(
          tenantId: userData['tenantId'] as String,
          uid: uid,
          email: userEmail,
          roles: roles,
        );
        _authState.setAuthenticated();
        if (!mounted) return;
        context.go('/trial-expired');
        return;
      }

      _tenantSession.setSessionWithRoles(
        tenantId: userData['tenantId'] as String,
        roles: roles,
        uid: uid,
        email: userEmail,
      );

      if (roles.contains('professional')) {
        String? professionalId = await _professionalRemote.linkUidToProfessionalByEmail(
          email: userEmail,
          uid: uid,
        );
        if (professionalId == null) {
          final prof = await _professionalRemote.getProfessionalByUid(uid);
          professionalId = prof?['id'] as String?;
        }
        if (professionalId != null) {
          _tenantSession.setProfessionalId(professionalId);
          await _tokenManager.saveSessionData(
            tenantId: userData['tenantId'] as String,
            uid: uid,
            email: userEmail,
            roles: roles,
            professionalId: professionalId,
          );
        } else if (!roles.contains('owner') && !roles.contains('admin')) {
          throw Exception('Profissional não encontrado para este email.');
        }
      } else {
        await _tokenManager.saveSessionData(
          tenantId: userData['tenantId'] as String,
          uid: uid,
          email: userEmail,
          roles: roles,
        );
      }

      _authState.setAuthenticated();
      if (!mounted) return;
      _redirectByRoles(roles);
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade700),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processInvite({
    required InviteEntity invite,
    required String uid,
    required String email,
  }) async {
    final professionalId = await _professionalRemote.linkUidToProfessionalByEmailInTenant(
      tenantId: invite.tenantId,
      email: email,
      uid: uid,
    );

    await _userRemote.createUser(
      uid: uid,
      email: email,
      role: invite.role,
      tenantId: invite.tenantId,
      name: invite.name,
    );

    await _inviteRepository.deleteInvite(email);

    final tenantSnapshot = await _tenantRemote.getTenant(invite.tenantId);
    final tenantData = tenantSnapshot.data();
    if (tenantData == null) throw Exception('Tenant não encontrado.');

    final status = tenantData['status'] ?? 'active';
    if (status != 'active') throw Exception('Seu salão está suspenso.');

    final planExpire = tenantData['planExpireDate'] ?? tenantData['expiresAt'];
    if (planExpire != null) {
      final DateTime dt = planExpire is Timestamp ? planExpire.toDate() : planExpire as DateTime;
      if (DateTime.now().isAfter(dt)) {
        _tenantSession.setSessionWithRoles(
          tenantId: invite.tenantId,
          roles: [invite.role],
          uid: uid,
          email: email,
        );
        if (professionalId != null) _tenantSession.setProfessionalId(professionalId);
        await _whiteLabel.load(invite.tenantId);
        await _tokenManager.saveSessionData(
          tenantId: invite.tenantId,
          uid: uid,
          email: email,
          roles: [invite.role],
          professionalId: professionalId,
        );
        _authState.setAuthenticated();
        if (!mounted) return;
        context.go('/trial-expired');
        return;
      }
    }

    _tenantSession.setSessionWithRoles(
      tenantId: invite.tenantId,
      roles: [invite.role],
      uid: uid,
      email: email,
    );
    if (professionalId != null) _tenantSession.setProfessionalId(professionalId);
    await _whiteLabel.load(invite.tenantId);
    await _tokenManager.saveSessionData(
      tenantId: invite.tenantId,
      uid: uid,
      email: email,
      roles: [invite.role],
      professionalId: professionalId,
    );

    _authState.setAuthenticated();
    if (!mounted) return;
    context.go('/professional');
  }

  void _redirectByRoles(List<String> roles) {
    if (roles.contains('owner') || roles.contains('admin')) {
      context.go('/admin');
    } else if (roles.contains('professional')) {
      context.go('/professional');
    } else {
      context.go('/client');
    }
  }

  static const _primary = AuthWelcomeColors.primary;
  static const _text = AuthWelcomeColors.textPrimary;
  static const _muted = AuthWelcomeColors.textMuted;
  static const _border = AuthWelcomeColors.border;
  static const _fill = AuthWelcomeColors.cardFill;

  @override
  Widget build(BuildContext context) {
    return AuthWelcomeLayout(
      showLogo: true,
      showFooter: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'E-mail',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _text,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'E-mail',
              filled: true,
              fillColor: _fill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                borderSide: const BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                borderSide: const BorderSide(color: _border),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Senha',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _text,
            ),
          ),
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.centerRight,
            children: [
              TextField(
                controller: _passwordController,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  hintText: 'Senha',
                  filled: true,
                  fillColor: _fill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    borderSide: const BorderSide(color: _border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    borderSide: const BorderSide(color: _border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                  color: _muted,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (v) => setState(() => _rememberMe = v ?? true),
                activeColor: _primary,
              ),
              GestureDetector(
                onTap: () => setState(() => _rememberMe = !_rememberMe),
                child: const Text(
                  'Lembrar-me',
                  style: TextStyle(fontSize: 14, color: _text),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Em breve')),
              );
            },
            child: const Text(
              'Esqueceu a senha?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          AuthWelcomePrimaryButton(
            label: 'Entrar',
            onPressed: _submit,
            isLoading: _isLoading,
            showArrow: false,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Não tem conta? ',
                style: TextStyle(fontSize: 14, color: _muted),
              ),
              GestureDetector(
                onTap: () => context.go('/register'),
                child: const Text(
                  'Criar conta',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
