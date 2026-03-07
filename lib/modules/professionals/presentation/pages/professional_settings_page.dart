import 'package:flutter/material.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';

/// Placeholder: configurações do profissional.
class ProfessionalSettingsPage extends StatelessWidget {
  const ProfessionalSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.settings_outlined,
            size: 64,
            color: AppColors.mutedForeground(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Configurações',
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
