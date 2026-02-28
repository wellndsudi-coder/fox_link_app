import 'package:flutter/material.dart';

class ProfessionalFinancePage extends StatelessWidget {
  const ProfessionalFinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Financeiro"),
      ),
      body: const Center(
        child: Text(
          "Resumo financeiro do profissional",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}