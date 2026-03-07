import 'package:flutter/material.dart';
import 'package:fox_link_app/modules/auth/domain/entities/onboarding_data.dart';
import 'package:fox_link_app/modules/onboarding/presentation/pages/create_salon_page.dart';
import 'package:fox_link_app/modules/onboarding/presentation/pages/join_salon_page.dart';
import 'package:fox_link_app/shared/widgets/app_card.dart';
import 'package:fox_link_app/shared/widgets/app_section_title.dart';

enum AccountType { salonOwner, client }

class AppleOnboardingPage extends StatelessWidget {
  final String uid;
  final String email;
  final String name;
  final String phone;

  const AppleOnboardingPage({
    super.key,
    required this.uid,
    required this.email,
    this.name = '',
    this.phone = '',
  });

  @override
  Widget build(BuildContext context) {
    final data = OnboardingData(
      uid: uid,
      name: name,
      email: email,
      phone: phone,
    );
    return Scaffold(
      appBar: AppBar(title: const Text("Criar Conta")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSectionTitle(
                  title: "Como você quer começar?",
                  subtitle: "Escolha o tipo de conta que deseja criar.",
                ),

                const SizedBox(height: 32),

                _optionCard(
                  context,
                  icon: Icons.storefront_outlined,
                  title: "Criar Salão",
                  subtitle: "Gerencie serviços e profissionais",
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateSalonPage(data: data),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                _optionCard(
                  context,
                  icon: Icons.person_outline,
                  title: "Criar Conta como Cliente",
                  subtitle: "Agendar serviços em um salão",
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JoinSalonPage(data: data),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _optionCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }
}