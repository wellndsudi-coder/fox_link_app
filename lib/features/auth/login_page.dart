import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/auth/domain/repositories/auth_repository.dart';
import 'package:fox_link_app/core/widgets/client_shell.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/professional_dashboard.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/admin_dashboard.dart';
import 'package:fox_link_app/modules/master/presentation/pages/master_dashboard.dart';
import 'package:fox_link_app/modules/onboarding/presentation/pages/onboarding_page.dart';
import 'package:fox_link_app/modules/users/infra/datasources/user_remote_datasource.dart';
import 'package:fox_link_app/modules/tenant/infra/datasources/tenant_remote_datasource.dart';
import 'package:fox_link_app/modules/subscription/presentation/pages/trial_expired_page.dart';
import 'package:fox_link_app/shared/widgets/app_card.dart';
import 'package:fox_link_app/shared/widgets/app_section_title.dart';

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

  bool isLogin = true;
  bool isLoading = false;

  Future<void> _submit() async {
    setState(() => isLoading = true);

    try {
      if (isLogin) {
        final user = await _authRepository.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        final userData = await _userRemote.getUser(user.uid);
        final role = userData['role'];

        if (role == 'master') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MasterDashboard()),
          );
          return;
        }

        final tenantData =
        await _tenantRemote.getTenant(userData['tenantId']);

        final status = tenantData['status'];
        final expiresAt =
        (tenantData['expiresAt'] as Timestamp).toDate();

        if (status != 'active') {
          throw Exception("Seu salão está suspenso.");
        }

        if (DateTime.now().isAfter(expiresAt)) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const TrialExpiredPage(),
            ),
          );
          return;
        }

        _tenantSession.setSession(
          tenantId: userData['tenantId'],
          role: role,
          uid: user.uid,
          email: user.email ?? '',
        );

        _redirectByRole(role);
      } else {
        final user = await _authRepository.register(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OnboardingPage(
              uid: user.uid,
              email: user.email ?? '',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => isLoading = false);
  }

  void _redirectByRole(String role) {
    if (role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    } else if (role == 'professional') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfessionalDashboard()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ClientShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                Text(
                  "Fox Link 🦊",
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge,
                ),

                const SizedBox(height: 8),

                Text(
                  isLogin
                      ? "Gerencie seu negócio com inteligência."
                      : "Crie sua conta e comece agora.",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium,
                ),

                const SizedBox(height: 32),

                AppCard(
                  child: Column(
                    children: [
                      TextField(
                        controller: _emailController,
                        decoration:
                        const InputDecoration(
                            labelText: "Email"),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration:
                        const InputDecoration(
                            labelText: "Senha"),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed:
                          isLoading ? null : _submit,
                          child: isLoading
                              ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                              : Text(
                            isLogin
                                ? "Entrar"
                                : "Criar Conta",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() =>
                      isLogin = !isLogin);
                    },
                    child: Text(
                      isLogin
                          ? "Não tem conta? Criar agora"
                          : "Já tem conta? Fazer login",
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}