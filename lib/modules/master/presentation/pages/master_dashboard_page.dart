import 'package:flutter/material.dart';
import 'package:fox_link_app/shared/widgets/dashboard_card.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import '../controllers/master_controller.dart';

class MasterDashboardPage extends StatefulWidget {
  final MasterController controller;

  const MasterDashboardPage({super.key, required this.controller});

  @override
  State<MasterDashboardPage> createState() => _MasterDashboardPageState();
}

class _MasterDashboardPageState extends State<MasterDashboardPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadMetrics();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (widget.controller.loading && widget.controller.metrics == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final m = widget.controller.metrics;
        if (m == null) {
          return const Center(child: Text('Erro ao carregar métricas'));
        }

        return RefreshIndicator(
          onRefresh: () => widget.controller.loadMetrics(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    DashboardCard(
                      label: 'Total Tenants',
                      value: '${m.totalTenants}',
                      icon: Icons.business,
                      iconColor: AppColors.onPrimary(context),
                    ),
                    DashboardCard(
                      label: 'Tenants Ativos',
                      value: '${m.activeTenants}',
                      icon: Icons.check_circle,
                      iconColor: AppColors.onPrimary(context),
                    ),
                    DashboardCard(
                      label: 'Usuários Totais',
                      value: '${m.totalUsers}',
                      icon: Icons.people,
                      iconColor: AppColors.onPrimary(context),
                    ),
                    DashboardCard(
                      label: 'Agendamentos Hoje',
                      value: '${m.appointmentsToday}',
                      icon: Icons.calendar_today,
                      iconColor: AppColors.onPrimary(context),
                    ),
                    DashboardCard(
                      label: 'Receita Mensal',
                      value: 'R\$ ${m.monthlyRevenue.toStringAsFixed(2).replaceAll('.', ',')}',
                      icon: Icons.attach_money,
                      iconColor: AppColors.onPrimary(context),
                    ),
                    DashboardCard(
                      label: 'Trial Ativos',
                      value: '${m.trialActive}',
                      icon: Icons.schedule,
                      iconColor: AppColors.onPrimary(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
