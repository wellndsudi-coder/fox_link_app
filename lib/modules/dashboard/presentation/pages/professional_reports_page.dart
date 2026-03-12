import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_professional_metrics_usecase.dart';
import 'package:fox_link_app/shared/widgets/dashboard_card.dart';
import 'package:fox_link_app/shared/widgets/app_card.dart';

class ProfessionalReportsPage extends StatefulWidget {
  const ProfessionalReportsPage({super.key});

  @override
  State<ProfessionalReportsPage> createState() => _ProfessionalReportsPageState();
}

class _ProfessionalReportsPageState extends State<ProfessionalReportsPage> {
  final _useCase = GetIt.I<GetProfessionalMetricsUseCase>();

  late Future<ProfessionalMetrics> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _useCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        _load();
        setState(() {});
      },
      child: FutureBuilder<ProfessionalMetrics>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar dados',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            );
          }

          final data = snapshot.data!;
          final occupancy = data.totalSlots == 0
              ? 0.0
              : (data.todayAppointments / data.totalSlots) * 100;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relatórios pessoais',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Resumo da sua atividade',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedForeground(context),
                  ),
                ),
                const SizedBox(height: 24),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2 / 1.5,
                  children: [
                    DashboardCard(
                      label: 'Atendimentos hoje',
                      value: data.todayAppointments.toString(),
                      subtitle: 'Hoje',
                      icon: Icons.calendar_today,
                      iconColor: theme.colorScheme.primary,
                    ),
                    DashboardCard(
                      label: 'Receita hoje',
                      value: 'R\$ ${data.todayRevenue.toStringAsFixed(2)}',
                      subtitle: 'Hoje',
                      icon: Icons.attach_money,
                      iconColor: AppColors.success(context),
                    ),
                    DashboardCard(
                      label: 'Agendamentos mês',
                      value: data.monthAppointmentCount.toString(),
                      subtitle: 'Este mês',
                      icon: Icons.calendar_month,
                      iconColor: theme.colorScheme.primary,
                    ),
                    DashboardCard(
                      label: 'Receita mês',
                      value: 'R\$ ${data.monthRevenue.toStringAsFixed(2)}',
                      subtitle: 'Este mês',
                      icon: Icons.trending_up,
                      iconColor: AppColors.success(context),
                    ),
                    DashboardCard(
                      label: 'Ocupação',
                      value: '${occupancy.toStringAsFixed(1)}%',
                      subtitle: 'Hoje',
                      icon: Icons.pie_chart,
                      iconColor: AppColors.mutedForeground(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (data.nextAppointment != null)
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Próximo atendimento',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat("dd/MM/yyyy 'às' HH:mm")
                              .format(data.nextAppointment!),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
