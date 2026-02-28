import 'package:flutter/material.dart';

class ProfessionalServicesPage extends StatelessWidget {
  const ProfessionalServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Meus Serviços"),
      ),
      body: const Center(
        child: Text(
          "Gestão de serviços do profissional",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}