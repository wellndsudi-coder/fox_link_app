import 'package:flutter/material.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/modules/auth/domain/entities/onboarding_data.dart';
import 'package:fox_link_app/modules/onboarding/presentation/pages/create_salon_page.dart';
import 'package:fox_link_app/modules/onboarding/presentation/pages/join_salon_page.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const OnboardingPage({
    super.key,
    required this.data,
  });

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

                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadius),
                    ),
                    child: const Icon(
                      Icons.pets,
                      size: 32,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bem-vindo!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.foregroundColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Como você gostaria de começar?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.mutedForeground,
                  ),
                ),

                const SizedBox(height: 40),

                _OptionCard(
                  icon: Icons.store,
                  title: 'Criar salão',
                  subtitle: 'Cadastre seu estabelecimento e comece a agendar',
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateSalonPage(data: data),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                _OptionCard(
                  icon: Icons.login,
                  title: 'Entrar em um salão',
                  subtitle:
                      'Use um código de convite para entrar como profissional',
                  useAccent: false,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JoinSalonPage(data: data),
                      ),
                    );
                  },
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

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool useAccent;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.useAccent = true,
  });

  @override
  Widget build(BuildContext context) {
    final iconBg = useAccent ? AppTheme.accentColor : AppTheme.secondaryColor;
    final iconFg = useAccent ? AppTheme.accentForeground : AppTheme.foregroundColor;

    return Material(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadius),
                ),
                child: Icon(icon, size: 24, color: iconFg),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.foregroundColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
