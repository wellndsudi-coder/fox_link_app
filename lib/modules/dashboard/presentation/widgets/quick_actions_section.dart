import 'package:flutter/material.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';

class QuickActionsSection extends StatelessWidget {
  final void Function(int pageIndex)? onNavigateToPage;

  const QuickActionsSection({
    super.key,
    this.onNavigateToPage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações rápidas',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _QuickActionCard(
                icon: Icons.add_circle_outline,
                label: 'Novo agendamento',
                onTap: () => onNavigateToPage?.call(1),
              ),
              const SizedBox(width: 12),
              _QuickActionCard(
                icon: Icons.person_add_outlined,
                label: 'Novo cliente',
                onTap: () => onNavigateToPage?.call(2),
              ),
              const SizedBox(width: 12),
              _QuickActionCard(
                icon: Icons.add_box_outlined,
                label: 'Novo serviço',
                onTap: () => onNavigateToPage?.call(4),
              ),
              const SizedBox(width: 12),
              _QuickActionCard(
                icon: Icons.block,
                label: 'Bloquear horário',
                onTap: () => onNavigateToPage?.call(1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary(context);

    return Material(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 120,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: primary),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
