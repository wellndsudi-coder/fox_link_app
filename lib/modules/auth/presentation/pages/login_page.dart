import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/auth/domain/repositories/auth_repository.dart';
import 'package:fox_link_app/modules/auth/presentation/pages/register_page.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/client_dashboard.dart';
import 'package:fox_link_app/core/widgets/admin_shell.dart';
import 'package:fox_link_app/modules/master/presentation/pages/master_dashboard.dart';
import 'package:fox_link_app/modules/subscription/presentation/pages/trial_expired_page.dart';
import 'package:fox_link_app/modules/users/infra/datasources/user_remote_datasource.dart';
import 'package:fox_link_app/modules/tenant/infra/datasources/tenant_remote_datasource.dart';
import 'package:fox_link_app/modules/professionals/presentation/pages/professional_panel.dart';
import 'package:fox_link_app/modules/professionals/infra/datasources/professional_remote_datasource.dart';

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
      final user = await _authRepository.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      final userData = await _userRemote.getUser(user.uid);
      final rolesRaw = userData['roles'];
      final List<String> roles = rolesRaw != null
          ? List<String>.from(rolesRaw as List)
          : [userData['role'] as String];

      if (roles.contains('master')) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MasterDashboard()),
        );
        return;
      }

      final tenantSnapshot =
          await _tenantRemote.getTenant(userData['tenantId']);
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TrialExpiredPage()),
        );
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

  void _redirectByRoles(List<String> roles) {
    if (roles.contains('owner') || roles.contains('admin')) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminShell()),
      );
    } else if (roles.contains('professional')) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfessionalPanel()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ClientDashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
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
                      color: AppTheme.accentColor,
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadius),
                    ),
                    child: const Icon(
                      Icons.pets,
                      size: 40,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'FOX LINK',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.foregroundColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Agendamento inteligente',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.mutedForeground,
                  ),
                ),

                const SizedBox(height: 32),

                // Form
                Text(
                  'E-mail',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.foregroundColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'seu@email.com',
                    filled: true,
                    fillColor: AppTheme.secondaryColor,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadius),
                      borderSide: BorderSide.none,
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.foregroundColor,
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
                        fillColor: AppTheme.secondaryColor,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.borderRadius),
                          borderSide: BorderSide.none,
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
                        color: AppTheme.mutedForeground,
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
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
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
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterPage(),
                          ),
                        );
                      },
                      child: Text(
                        'Criar conta',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
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
