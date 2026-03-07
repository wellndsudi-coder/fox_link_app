import 'package:flutter/material.dart';
import 'package:fox_link_app/modules/subscription/presentation/pages/plans_page.dart';

class TrialExpiredPage extends StatelessWidget {
  const TrialExpiredPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              const Text(
                "Seu período de teste expirou",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Para continuar utilizando o Fox Link, escolha um plano.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PlansPage(),
                    ),
                  );
                },
                child: const Text("Escolher Plano"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}