import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/auth/domain/repositories/auth_repository.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/client_dashboard.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/professional_dashboard.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/admin_dashboard.dart';
import 'package:fox_link_app/modules/users/infra/datasources/user_remote_datasource.dart';
import 'package:fox_link_app/modules/tenant/infra/datasources/tenant_remote_datasource.dart';

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
        // 🔐 LOGIN
        final user = await _authRepository.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        final userData = await _userRemote.getUser(user.uid);

        final tenantData =
        await _tenantRemote.getTenant(userData['tenantId']);

        final status = tenantData['status'];
        final expiresAt =
        (tenantData['expiresAt'] as Timestamp).toDate();

        // 🚨 VALIDAÇÃO DE STATUS
        if (status != 'active') {
          throw Exception("Seu salão está suspenso.");
        }

        // 🚨 VALIDAÇÃO DE EXPIRAÇÃO
        if (DateTime.now().isAfter(expiresAt)) {
          throw Exception("Seu período de teste expirou.");
        }

        // 🔥 Salva sessão
        _tenantSession.setSession(
          tenantId: userData['tenantId'],
          role: userData['role'],
          uid: user.uid,
          email: user.email ?? '',
        );

        _redirectByRole(userData['role']);
      } else {
        // 🏢 CRIAR NOVO SALÃO (TRIAL 7 DIAS)

        final user = await _authRepository.register(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        final tenantId = await _tenantRemote.createTenant(
          name: "Meu Salão",
          ownerId: user.uid,
        );

        await _userRemote.createUser(
          uid: user.uid,
          email: user.email ?? '',
          role: 'admin',
          tenantId: tenantId,
        );

        _tenantSession.setSession(
          tenantId: tenantId,
          role: 'admin',
          uid: user.uid,
          email: user.email ?? '',
        );

        _redirectByRole('admin');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => isLoading = false);
  }

  void _redirectByRole(String role) {
    if (!mounted) return;

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
        MaterialPageRoute(builder: (_) => const ClientDashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                "Fox Link App 🦊",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Senha"),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isLogin ? "Entrar" : "Criar Salão"),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() => isLogin = !isLogin);
                },
                child: Text(
                  isLogin
                      ? "Não tem salão? Criar agora"
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