import 'package:flutter/material.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';

/// Badge de status do tenant para o painel Master.
class TenantStatusBadge extends StatelessWidget {
  final String status;

  const TenantStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = _statusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  (Color, String) _statusStyle(String s) {
    switch (s.toLowerCase()) {
      case 'active':
      case 'paid':
        return (AppColors.successColor, 'Ativo');
      case 'suspended':
      case 'blocked':
        return (const Color(0xFFDC2626), 'Bloqueado');
      case 'trial':
        return (AppColors.warningColor, 'Trial');
      case 'cancelled':
        return (Colors.grey, 'Cancelado');
      default:
        return (Colors.grey, s);
    }
  }
}
