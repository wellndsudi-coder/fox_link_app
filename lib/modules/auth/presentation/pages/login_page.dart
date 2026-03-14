import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/core/auth/auth_state.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/auth/domain/entities/onboarding_data.dart';
import 'package:fox_link_app/modules/auth/domain/repositories/auth_repository.dart';
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

  final _authRepository = getIt<AuthRepository>();
  final _userRemote = getIt<UserRemoteDataSource>();
  final _tenantRemote = getIt<TenantRemoteDataSource>();
  final _tenantSession = getIt<TenantSession>();
  final _professionalRemote = getIt<ProfessionalRemoteDataSource>();
  final _inviteRepository = getIt<InviteRepository>();
  final _whiteLabel = getIt<WhiteLabelService>();

  bool _showPassword = false;
  bool _isLoading = false;

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
      final user = await _authRepository.signIn(
        email,
        _passwordController.text.trim(),
      );

      // Usuário existente que recebeu convite: processar e redirecionar
      final invite = await _inviteRepository.getInviteByEmail(email);
      if (invite != null) {
        final professionalId =
            await _professionalRemote.linkUidToProfessionalByEmailInTenant(
          tenantId: invite.tenantId,
          email: email,
          uid: user.uid,
        );

        await _userRemote.createUser(
          uid: user.uid,
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
              uid: user.uid,
              email: email,
            );
            if (professionalId != null) _tenantSession.setProfessionalId(professionalId);
            await _whiteLabel.load(invite.tenantId);
            if (!mounted) return;
            context.go('/trial-expired');
            return;
          }
        }

        _tenantSession.setSessionWithRoles(
          tenantId: invite.tenantId,
          roles: [invite.role],
          uid: user.uid,
          email: email,
        );
        if (professionalId != null) _tenantSession.setProfessionalId(professionalId);
        await _whiteLabel.load(invite.tenantId);

        if (!mounted) return;
        context.go('/professional');
        return;
      }

      final userData = await _userRemote.getUser(user.uid);
      final tenantId = userData['tenantId'] as String?;
      final rolesRaw = userData['roles'];
      final roleSingle = userData['role'] as String?;
      final List<String> roles = rolesRaw != null
          ? List<String>.from(rolesRaw as List)
          : (roleSingle != null ? [roleSingle] : <String>[]);

      // Master/Super Admin: pode acessar sem tenantId
      if (roles.contains('master') || roles.contains('super_admin')) {
        _tenantSession.setSessionWithRoles(
          tenantId: tenantId ?? '',
          roles: roles,
          uid: user.uid,
          email: user.email ?? userData['email'] as String? ?? '',
        );
        getIt<AuthState>().setAuthenticated();
        if (!mounted) return;
        context.go('/master');
        return;
      }

      // Perfil incompleto: criou conta mas não completou "Criar salão"
      if (tenantId == null || roles.isEmpty) {
        final email = userData['email'] as String? ?? user.email;
        final name = userData['name'] as String? ?? (email != null ? email.split('@').first : '');
        final phone = userData['phone'] as String? ?? '';
        if (!mounted) return;
        context.go('/onboarding', extra: OnboardingData(
          uid: user.uid,
          email: email ?? '',
          name: name,
          phone: phone,
        ));
        return;
      }

      final tenantSnapshot =
          await _tenantRemote.getTenant(tenantId);
      final tenantData = tenantSnapshot.data();

      if (tenantData == null) {
        throw Exception('Tenant não encontrado.');
      }

      final status = tenantData['status'] ?? 'active';
      DateTime? expiresAt;
      if (tenantData['expiresAt'] != null) {
        expiresAt = (tenantData['expiresAt'] as Timestamp).toDate();
      }

      if (status != 'active') {
        throw Exception('Seu salão está suspenso.');
      }

      if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
        context.go('/trial-expired');
        return;
      }

      _tenantSession.setSessionWithRoles(
        tenantId: userData['tenantId'] as String,
        roles: roles,
        uid: user.uid,
        email: user.email,
      );

      if (roles.contains('professional')) {
        String? professionalId;
        professionalId = await _professionalRemote
            .linkUidToProfessionalByEmail(
          email: user.email,
          uid: user.uid,
        );
        if (professionalId == null) {
          final prof = await _professionalRemote.getProfessionalByUid(
            user.uid,
          );
          if (prof != null && prof['id'] != null) {
            professionalId = prof['id'] as String;
          }
        }
        if (professionalId != null) {
          _tenantSession.setProfessionalId(professionalId);
        } else if (!roles.contains('owner') && !roles.contains('admin')) {
          throw Exception('Profissional não encontrado para este email.');
        }
      }

      _redirectByRoles(roles);
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

  // Cores fixas para login (sem white label)
  static const _loginPrimary = Color(0xFFFF6A00);
  static const _loginBackground = Color(0xFFF7F9FC);
  static const _loginText = Color(0xFF1F2937);
  static const _loginBorder = Color(0xFFE5E7EB);
  static const _loginMuted = Color(0xFF64748B);
  static const _loginFill = Color(0xFFFFFFFF);

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
      backgroundColor: _loginBackground,
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

                // Logo
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _loginPrimary.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadius),
                      border: Border.all(color: _loginBorder),
                    ),
                    child: Center(
                      child: Text('🦊', style: const TextStyle(fontSize: 44)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'FoX LinK',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _loginText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Agendamento inteligente',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: _loginMuted,
                  ),
                ),

                const SizedBox(height: 32),

                // Form
                Text(
                  'E-mail',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _loginText,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'E-mail',
                    filled: true,
                    fillColor: _loginFill,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadius),
                      borderSide: const BorderSide(color: _loginBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadius),
                      borderSide: const BorderSide(color: _loginBorder),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Senha',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _loginText,
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
                        fillColor: _loginFill,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.borderRadius),
                          borderSide: const BorderSide(color: _loginBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.borderRadius),
                          borderSide: const BorderSide(color: _loginBorder),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: _loginMuted,
                        size: 20,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

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
                      color: _loginPrimary,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _loginPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadius),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Entrar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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
                        color: _loginMuted,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: Text(
                        'Criar conta',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _loginPrimary,
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
