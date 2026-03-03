import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

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
        bgColor = AppTheme.warningColor.withOpacity(0.1);
        textColor = AppTheme.warningColor;
        label = "Pendente";
        break;
      case AppStatus.approved:
        bgColor = AppTheme.successColor.withOpacity(0.1);
        textColor = AppTheme.successColor;
        label = "Aprovado";
        break;
      case AppStatus.rejected:
        bgColor = AppTheme.errorColor.withOpacity(0.1);
        textColor = AppTheme.errorColor;
        label = "Recusado";
        break;
      case AppStatus.cancelled:
        bgColor = Colors.grey.withOpacity(0.15);
        textColor = Colors.grey;
        label = "Cancelado";
        break;
      case AppStatus.completed:
        bgColor = AppTheme.primaryColor.withOpacity(0.1);
        textColor = AppTheme.primaryColor;
        label = "Concluído";
        break;
      case AppStatus.active:
        bgColor = AppTheme.successColor.withOpacity(0.1);
        textColor = AppTheme.successColor;
        label = "Ativo";
        break;
      case AppStatus.inactive:
        bgColor = Colors.grey.withOpacity(0.15);
        textColor = Colors.grey;
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