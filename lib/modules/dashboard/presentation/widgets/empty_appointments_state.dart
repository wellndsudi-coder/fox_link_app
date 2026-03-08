import 'package:flutter/material.dart';

import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/shared/widgets/app_button.dart';

class EmptyAppointmentsState extends StatelessWidget {
  final VoidCallback? onBookTap;

  const EmptyAppointmentsState({
    super.key,
    this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 72,
              color: AppColors.mutedForeground(context).withValues(alpha: 0.6),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhum agendamento',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Que tal agendar seu primeiro serviço?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedForeground(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (onBookTap != null)
              AppButton(
                text: 'Agendar serviço',
                onPressed: onBookTap,
              ),
          ],
        ),
      ),
    );
  }
}
