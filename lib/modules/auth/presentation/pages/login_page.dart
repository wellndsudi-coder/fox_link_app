import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/auth/domain/repositories/auth_repository.dart';
import 'package:fox_link_app/modules/auth/domain/usecases/register_user_usecase.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/client_dashboard.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/admin_dashboard.dart';
import 'package:fox_link_app/modules/master/presentation/pages/master_dashboard.dart';
import 'package:fox_link_app/modules/subscription/presentation/pages/trial_expired_page.dart';
import 'package:fox_link_app/modules/users/infra/datasources/user_remote_datasource.dart';
import 'package:fox_link_app/modules/tenant/infra/datasources/tenant_remote_datasource.dart';
import 'package:fox_link_app/modules/onboarding/presentation/pages/onboarding_page.dart';
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
  final _registerUseCase = getIt<RegisterUserUseCase>();
  final _userRemote = getIt<UserRemoteDataSource>();
  final _tenantRemote = getIt<TenantRemoteDataSource>();
  final _tenantSession = getIt<TenantSession>();
  final _professionalRemote = getIt<ProfessionalRemoteDataSource>();

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
            MaterialPageRoute(
              builder: (_) => const MasterDashboard(),
            ),
          );
          return;
        }

        final tenantSnapshot =
        await _tenantRemote.getTenant(userData['tenantId']);

        final tenantData = tenantSnapshot.data();

        if (tenantData == null) {
          throw Exception("Tenant não encontrado.");
        }

        final status = tenantData['status'] ?? 'active';

        DateTime? expiresAt;

        if (tenantData['expiresAt'] != null) {
          expiresAt =
              (tenantData['expiresAt'] as Timestamp).toDate();
        }

        if (status != 'active') {
          throw Exception("Seu salão está suspenso.");
        }

        if (expiresAt != null &&
            DateTime.now().isAfter(expiresAt)) {
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

        // 🔥 VINCULAR PROFESSIONAL AO UID (OPÇÃO A CORRETA)
        if (role == 'professional') {
          final professionalId =
          await _professionalRemote.linkUidToProfessionalByEmail(
            email: user.email ?? '',
            uid: user.uid,
          );

          if (professionalId == null) {
            throw Exception(
                "Profissional não encontrado para este email.");
          }

          _tenantSession.setProfessionalId(professionalId);
        }

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

          // 🔥 VINCULAR PROFESSIONAL AO UID
          final professionalId =
          await _professionalRemote.linkUidToProfessionalByEmail(
            email: result.email,
            uid: result.uid,
          );

          if (professionalId == null) {
            throw Exception(
                "Profissional não encontrado para este email.");
          }

          _tenantSession.setProfessionalId(professionalId);

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
          builder: (_) => ProfessionalPanel(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ClientDashboard(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const CircleAvatar(
                radius: 32,
                backgroundColor: Color(0xFF7C3AED),
                child: Icon(Icons.auto_awesome,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                "FOX LINK",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isLogin
                    ? "Acesse seu painel"
                    : "Crie sua conta em minutos",
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: _inputDecoration("Email"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: _inputDecoration("Senha"),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
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
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  setState(() => isLogin = !isLogin);
                },
                child: Text(
                  isLogin
                      ? "Não tem conta? Criar agora"
                      : "Já tem conta? Fazer login",
                  style:
                  const TextStyle(color: Color(0xFF7C3AED)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}