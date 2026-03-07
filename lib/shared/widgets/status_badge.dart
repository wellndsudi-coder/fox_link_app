import 'package:flutter/material.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';

enum AppStatus {
  pending,
  approved,
  rejected,
  cancelled,
  completed,
  active,
  inactive,
}

class StatusBadge extends StatelessWidget {
  final AppStatus status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case AppStatus.pending:
        bgColor = AppColors.warning(context).withValues(alpha: 0.1);
        textColor = AppColors.warning(context);
        label = "Pendente";
        break;
      case AppStatus.approved:
        bgColor = AppColors.success(context).withValues(alpha: 0.1);
        textColor = AppColors.success(context);
        label = "Aprovado";
        break;
      case AppStatus.rejected:
        bgColor = AppColors.error(context).withValues(alpha: 0.1);
        textColor = AppColors.error(context);
        label = "Recusado";
        break;
      case AppStatus.cancelled:
        bgColor = AppColors.mutedForeground(context).withValues(alpha: 0.15);
        textColor = AppColors.mutedForeground(context);
        label = "Cancelado";
        break;
      case AppStatus.completed:
        bgColor = AppColors.primary(context).withValues(alpha: 0.1);
        textColor = AppColors.primary(context);
        label = "Concluído";
        break;
      case AppStatus.active:
        bgColor = AppColors.success(context).withValues(alpha: 0.1);
        textColor = AppColors.success(context);
        label = "Ativo";
        break;
      case AppStatus.inactive:
        bgColor = AppColors.mutedForeground(context).withValues(alpha: 0.15);
        textColor = AppColors.mutedForeground(context);
        label = "Inativo";
        break;
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}