import 'package:flutter/material.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/modules/auth/domain/usecases/register_user_usecase.dart';
import 'package:fox_link_app/modules/onboarding/presentation/pages/onboarding_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _registerUseCase = getIt<RegisterUserUseCase>();

  bool _showPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validate() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty) return 'Informe seu nome.';
    if (email.isEmpty) return 'Informe seu email.';
    if (!email.contains('@')) return 'Email inválido.';
    if (phone.isEmpty) return 'Informe seu telefone.';
    if (password.isEmpty) return 'Informe a senha.';
    if (password.length < 6) return 'Senha deve ter no mínimo 6 caracteres.';
    if (password != confirm) return 'As senhas não coincidem.';

    return null;
  }

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _registerUseCase.execute(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result.isProfessional) {
        throw Exception('Cadastro com convite deve ser feito pelo fluxo anterior.');
      }

      if (result.onboardingData == null) {
        throw Exception('Erro ao processar cadastro.');
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OnboardingPage(data: result.onboardingData!),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppTheme.secondaryColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  children: [
                    Icon(Icons.arrow_back,
                        size: 18, color: AppTheme.mutedForeground),
                    const SizedBox(width: 4),
                    Text(
                      'Voltar',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Criar conta',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.foregroundColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Preencha seus dados para começar',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.mutedForeground,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Nome completo',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.foregroundColor,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration('João da Silva'),
              ),

              const SizedBox(height: 16),

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
                autocorrect: false,
                decoration: _inputDecoration('seu@email.com'),
              ),

              const SizedBox(height: 16),

              Text(
                'Telefone',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.foregroundColor,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('(11) 99999-9999'),
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
                    decoration: _inputDecoration('••••••••'),
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

              const SizedBox(height: 16),

              Text(
                'Confirmar senha',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.foregroundColor,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: _inputDecoration('••••••••'),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
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
                          'Criar conta',
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
                    'Já tem conta? ',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Entrar',
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
    );
  }
}
