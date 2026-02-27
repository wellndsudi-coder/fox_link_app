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

  bool isLogin = true;   // Alterna entre Login e Registro
  bool isLoading = false;

  // ==========================================================
  // 🔥 MÉTODO PRINCIPAL (LOGIN OU REGISTRO)
  // ==========================================================
  Future<void> _submit() async {
    setState(() => isLoading = true);

    try {
      if (isLogin) {
        // ==========================================================
        // 🔐 FLUXO DE LOGIN
        // ==========================================================

        // 1️⃣ Autentica no Firebase Auth
        final user = await _authRepository.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // 2️⃣ Busca dados do usuário no Firestore
        final userData = await _userRemote.getUser(user.uid);
        final role = userData['role'];

        // 3️⃣ Caso especial: Master não pertence a tenant
        if (role == 'master') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const MasterDashboard(),
            ),
          );
          return;
        }

        // 4️⃣ Busca dados do tenant
        final tenantData =
        await _tenantRemote.getTenant(userData['tenantId']);

        final status = tenantData['status'];
        final expiresAt =
        (tenantData['expiresAt'] as Timestamp).toDate();

        // 5️⃣ Validação de status do salão
        if (status != 'active') {
          throw Exception("Seu salão está suspenso.");
        }

        // 6️⃣ Validação de plano expirado
        if (DateTime.now().isAfter(expiresAt)) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const TrialExpiredPage(),
            ),
          );
          return;
        }

        // 7️⃣ Salva sessão ativa
        _tenantSession.setSession(
          tenantId: userData['tenantId'],
          role: role,
          uid: user.uid,
          email: user.email ?? '',
        );

        // 8️⃣ Redireciona conforme role
        _redirectByRole(role);

      } else {
        // ==========================================================
        // 🏢 FLUXO DE REGISTRO
        // ==========================================================

        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        // 1️⃣ Executa UseCase de registro
        final result = await _registerUseCase.execute(
          email: email,
          password: password,
        );

        // 2️⃣ Se for profissional convidado
        if (result.isProfessional) {

          // Salva sessão
          _tenantSession.setSession(
            tenantId: result.tenantId!,
            role: result.role!,
            uid: result.uid,
            email: result.email,
          );

          // Redireciona conforme role
          _redirectByRole(result.role!);

        } else {
          // 3️⃣ Se NÃO for convite → é novo salão (admin)

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
      // ==========================================================
      // 🚨 TRATAMENTO DE ERRO
      // ==========================================================
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => isLoading = false);
  }

  // ==========================================================
  // 🔄 REDIRECIONAMENTO POR ROLE
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
          builder: (_) => ProfessionalDashboard(),
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
  // 🎨 INTERFACE
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // Logo / Nome do app
              const Text(
                "Fox Link 🦊",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 40),

              // Campo Email
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                ),
              ),

              const SizedBox(height: 20),

              // Campo Senha
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Senha",
                ),
              ),

              const SizedBox(height: 30),

              // Botão principal
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                )
                    : Text(
                  isLogin ? "Entrar" : "Criar Conta",
                ),
              ),

              // Alterna entre login e registro
              TextButton(
                onPressed: () {
                  setState(() => isLogin = !isLogin);
                },
                child: Text(
                  isLogin
                      ? "Não tem conta? Criar agora"
                      : "Já tem conta? Fazer login",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}