import 'package:flutter/material.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';

/// Placeholder: lista de clientes do profissional.
class ProfessionalClientsPage extends StatelessWidget {
  const ProfessionalClientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.mutedForeground(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Meus clientes',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary(context),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Em breve',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.mutedForeground(context),
            ),
          ),
        ],
      ),
    );
  }
}
