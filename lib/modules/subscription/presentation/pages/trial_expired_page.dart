import 'package:flutter/material.dart';

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
            children: const [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.orange,
              ),
              SizedBox(height: 24),
              Text(
                "Seu período de teste expirou",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                "Para continuar utilizando o Fox Link, escolha um plano.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: null, // Vamos ativar depois
                child: Text("Escolher Plano"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}