import 'package:flutter/material.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';

class ProfessionalFinancePage extends StatelessWidget {
  const ProfessionalFinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.card(context),
        title: const Text("Financeiro"),
      ),
      body: Center(
        child: Text(
          "Resumo financeiro do profissional",
          style: TextStyle(color: AppColors.textPrimary(context)),
        ),
      ),
    );
  }
}