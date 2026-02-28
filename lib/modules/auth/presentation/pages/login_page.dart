import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/auth/domain/repositories/auth_repository.dart';
import 'package:fox_link_app/modules/auth/domain/usecases/register_user_usecase.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/client_dashboard.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/professional_dashboard.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/admin_dashboard.dart';
import 'package:fox_link_app/modules/master/presentation/pages/master_dashboard.dart';
import 'package:fox_link_app/modules/subscription/presentation/pages/trial_expired_page.dart';
import 'package:fox_link_app/modules/users/infra/datasources/user_remote_datasource.dart';
import 'package:fox_link_app/modules/tenant/infra/datasources/tenant_remote_datasource.dart';
import 'package:fox_link_app/modules/onboarding/presentation/pages/onboarding_page.dart';
import 'package:fox_link_app/modules/professionals/presentation/pages/professional_panel.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  // ================= CONTROLADORES =================
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ================= DEPENDÊNCIAS =================
  final _authRepository = getIt<AuthRepository>();
  final _registerUseCase = getIt<RegisterUserUseCase>();
  final _userRemote = getIt<UserRemoteDataSource>();
  final _tenantRemote = getIt<TenantRemoteDataSource>();
  final _tenantSession = getIt<TenantSession>();

  bool isLogin = true;
  bool isLoading = false;

  // ==========================================================
  // 🔥 LOGIN / REGISTRO
  // ==========================================================
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
            MaterialPageRoute(
              builder: (_) => const MasterDashboard(),
            ),
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
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        final result = await _registerUseCase.execute(
          email: email,
          password: password,
        );

        if (result.isProfessional) {
          _tenantSession.setSession(
            tenantId: result.tenantId!,
            role: result.role!,
            uid: result.uid,
            email: result.email,
          );

          _redirectByRole(result.role!);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OnboardingPage(
                uid: result.uid,
                email: result.email,
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => isLoading = false);
  }

  // ==========================================================
  // 🔄 REDIRECIONAMENTO
  // ==========================================================
  void _redirectByRole(String role) {
    if (role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminDashboard(),
        ),
      );
    } else if (role == 'professional') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ProfessionalPanel(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ClientDashboard(),
        ),
      );
    }
  }

  // ==========================================================
  // 🎨 UI PREMIUM
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Icon(
                  Icons.content_cut,
                  size: 48,
                  color: Colors.white,
                ),

                const SizedBox(height: 12),

                const Text(
                  "FOX LINK",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  isLogin
                      ? "Acesse seu painel profissional"
                      : "Crie seu salão em minutos",
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("Email"),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("Senha"),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF3B82F6),
                            Color(0xFF8B5CF6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: isLoading
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : Text(
                          isLogin ? "Entrar" : "Criar Conta",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: () {
                    setState(() => isLogin = !isLogin);
                  },
                  child: Text(
                    isLogin
                        ? "Não tem conta? Criar agora"
                        : "Já tem conta? Fazer login",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF334155),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}