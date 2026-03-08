import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';

class AdminDashboardHeader extends StatelessWidget {
  final String userName;
  final int appointmentsToday;
  final VoidCallback? onRefresh;

  const AdminDashboardHeader({
    super.key,
    required this.userName,
    required this.appointmentsToday,
    this.onRefresh,
  });

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  String _formatDate() {
    final now = DateTime.now();
    final weekday = DateFormat.E('pt_BR').format(now);
    final date = DateFormat('d \'de\' MMMM', 'pt_BR').format(now);
    return '${weekday[0].toUpperCase()}${weekday.substring(1)} • $date';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting()}, $userName 👋',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedForeground(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appointmentsToday == 0
                          ? 'Nenhum agendamento hoje'
                          : 'Você tem $appointmentsToday ${appointmentsToday == 1 ? 'agendamento' : 'agendamentos'} hoje',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedForeground(context),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Atualizar',
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: 'Notificações',
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary(context),
                    child: Text(
                      userName.isNotEmpty
                          ? userName.substring(0, 1).toUpperCase()
                          : '?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
