import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/core/auth/auth_state.dart';
import 'package:fox_link_app/core/auth/token_manager.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/auth/infra/auth_api_impl.dart';
import 'package:fox_link_app/features/login/domain/login_use_case.dart';
import 'package:fox_link_app/modules/auth/domain/entities/invite_entity.dart';
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
      final rolesRaw = userData['roles'];
      final roles = rolesRaw != null
          ? List<String>.from(rolesRaw as List)
          : [userData['role'] as String];

      if (roles.contains('master')) {
        _authState.setAuthenticated();
        if (!mounted) return;
        context.go('/master');
        return;
      }

      final tenantSnapshot = await _tenantRemote.getTenant(userData['tenantId']);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.accent(context),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    ),
                    child: Icon(Icons.pets, size: 40, color: AppColors.primary(context)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'FOX LINK',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Agendamento inteligente',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedForeground(context),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'E-mail',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'seu@email.com',
                    filled: true,
                    fillColor: AppColors.fillColor(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Senha',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary(context),
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
                        hintText: '••••••••',
                        filled: true,
                        fillColor: AppColors.fillColor(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                      icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.mutedForeground(context),
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
                      activeColor: AppColors.primary(context),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      child: Text(
                        'Lembrar-me',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary(context),
                        ),
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
                  child: Text(
                    'Esqueceu a senha?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary(context),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary(context),
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.onPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Entrar',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Não tem conta? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.mutedForeground(context),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: Text(
                        'Criar conta',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
