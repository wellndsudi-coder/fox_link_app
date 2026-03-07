import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../domain/usecases/get_admin_metrics_usecase.dart';
import '../../domain/usecases/get_today_agenda_usecase.dart';
import '../../domain/usecases/get_top_services_usecase.dart';
import '../../domain/usecases/get_weekly_revenue_usecase.dart';
import 'package:fox_link_app/shared/widgets/app_header.dart';
import 'package:fox_link_app/shared/widgets/appointment_card.dart';
import 'package:fox_link_app/shared/widgets/dashboard_card.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';

class AdminDashboard extends StatefulWidget {
  final ValueListenable<int>? refreshTrigger;
  final void Function(int pageIndex)? onNavigateToPage;

  const AdminDashboard({
    super.key,
    this.refreshTrigger,
    this.onNavigateToPage,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _metricsUseCase = GetIt.I<GetAdminMetricsUseCase>();
  final _agendaUseCase = GetIt.I<GetTodayAgendaUseCase>();
  final _topServicesUseCase = GetIt.I<GetTopServicesUseCase>();
  final _weeklyRevenueUseCase = GetIt.I<GetWeeklyRevenueUseCase>();

  late Future<({
    AdminMetrics metrics,
    List<TodayAppointmentDisplay> agenda,
    List<TopServiceItem> topServices,
    List<DailyRevenue> weeklyRevenue,
  })> _future;

  @override
  void initState() {
    super.initState();
    _loadData();
    widget.refreshTrigger?.addListener(_loadData);
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _future = Future.wait([
        _metricsUseCase(),
        _agendaUseCase(),
        _topServicesUseCase(),
        _weeklyRevenueUseCase(),
      ]).then((results) => (
            metrics: results[0] as AdminMetrics,
            agenda: results[1] as List<TodayAppointmentDisplay>,
            topServices: results[2] as List<TopServiceItem>,
            weeklyRevenue: results[3] as List<DailyRevenue>,
          ));
    });
  }

  String _getUserName() {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName;
    if (name != null && name.isNotEmpty) return name.split(' ').first;
    final email = user?.email;
    if (email != null && email.isNotEmpty) return email.split('@').first;
    return 'Usuário';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: FutureBuilder<
          ({AdminMetrics metrics, List<TodayAppointmentDisplay> agenda, List<TopServiceItem> topServices, List<DailyRevenue> weeklyRevenue})>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar métricas'));
          }

          final data = snapshot.data!;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppHeader.greeting(
                  name: _getUserName(),
                  subtitle: 'Aqui está o resumo de hoje',
                ),

                const SizedBox(height: 24),

                _buildMetricsGrid(data.metrics),

                const SizedBox(height: 32),

                _buildWeeklyRevenueChart(data.weeklyRevenue),

                const SizedBox(height: 32),

                _buildTopServicesChart(data.topServices),

                const SizedBox(height: 32),

                _buildTodayAgendaSection(data.agenda),

                const SizedBox(height: 32),

                _buildTopServicesSection(data.topServices),

                const SizedBox(height: 32),

                _buildMenuSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeeklyRevenueChart(List<DailyRevenue> weeklyRevenue) {
    final theme = Theme.of(context);
    final maxY = weeklyRevenue.isEmpty
        ? 100.0
        : (weeklyRevenue.map((d) => d.revenue).reduce((a, b) => a > b ? a : b) * 1.2).clamp(10.0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Faturamento semanal',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: weeklyRevenue.isEmpty
              ? Center(
                  child: Text(
                    'Sem dados de faturamento',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedForeground(context),
                    ),
                  ),
                )
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i >= 0 && i < weeklyRevenue.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  DateFormat('dd/MM').format(weeklyRevenue[i].date),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.mutedForeground(context),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                          reservedSize: 32,
                          interval: 1,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          getTitlesWidget: (value, meta) => Text(
                            'R\$${value.toInt()}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.mutedForeground(context),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY / 4,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: AppColors.border(context),
                        strokeWidth: 1,
                      ),
                    ),
                    barGroups: weeklyRevenue.asMap().entries.map((e) {
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value.revenue,
                            color: theme.colorScheme.primary,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                        showingTooltipIndicators: [],
                      );
                    }).toList(),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 200),
                ),
        ),
      ],
    );
  }

  Widget _buildTopServicesChart(List<TopServiceItem> topServices) {
    final theme = Theme.of(context);
    if (topServices.isEmpty) return const SizedBox.shrink();

    final maxCount = topServices.map((s) => s.count).reduce((a, b) => a > b ? a : b).toDouble();
    final maxY = (maxCount * 1.2).clamp(1.0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Serviços mais vendidos',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i >= 0 && i < topServices.length) {
                        final name = topServices[i].serviceName;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            name.length > 8 ? '${name.substring(0, 8)}...' : name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.mutedForeground(context),
                              fontSize: 10,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                    reservedSize: 32,
                    interval: 1,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedForeground(context),
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppColors.border(context),
                  strokeWidth: 1,
                ),
              ),
              barGroups: topServices.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.count.toDouble(),
                      color: theme.colorScheme.secondary,
                      width: 24,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                  showingTooltipIndicators: [],
                );
              }).toList(),
            ),
            swapAnimationDuration: const Duration(milliseconds: 200),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(AdminMetrics metrics) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        DashboardCard(
          label: 'Agendamentos',
          value: metrics.totalSlots.toString(),
          subtitle: 'Hoje',
          icon: Icons.calendar_today,
          iconColor: AppColors.primary(context),
        ),
        DashboardCard(
          label: 'Clientes',
          value: metrics.clientsServed.toString(),
          subtitle: 'Atendidos',
          icon: Icons.people,
          iconColor: AppColors.primary(context),
        ),
        DashboardCard(
          label: 'Faturamento',
          value: 'R\$ ${metrics.todayRevenue.toStringAsFixed(2)}',
          subtitle: 'Hoje',
          trend: metrics.revenueTrend,
          icon: Icons.attach_money,
          iconColor: AppColors.success(context),
        ),
        DashboardCard(
          label: 'Serviços',
          value: metrics.servicesCompleted.toString(),
          subtitle: 'Realizados',
          icon: Icons.design_services,
          iconColor: AppColors.accent(context),
        ),
      ],
    );
  }

  Widget _buildTodayAgendaSection(List<TodayAppointmentDisplay> agenda) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Agenda de hoje',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            TextButton(
              onPressed: () => widget.onNavigateToPage?.call(1),
              child: const Text('Ver tudo'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (agenda.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
            child: Center(
              child: Text(
                'Nenhum agendamento para hoje',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedForeground(context),
                    ),
              ),
            ),
          )
        else
          ...agenda.take(5).map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _appointmentCardFromDisplay(context, a),
              )),
      ],
    );
  }

  Widget _appointmentCardFromDisplay(BuildContext context, TodayAppointmentDisplay d) {
    final (label, color) = _statusLabelAndColor(context, d.status);
    return AppointmentCard(
      clientName: d.clientName,
      statusLabel: label,
      statusColor: color,
      time: d.time,
      serviceName: d.serviceName,
      professionalName: d.professionalName,
    );
  }

  (String, Color) _statusLabelAndColor(BuildContext context, AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.approved:
        return ('Confirmado', AppColors.success(context));
      case AppointmentStatus.pending:
        return ('Pendente', AppColors.warning(context));
      case AppointmentStatus.completed:
        return ('Concluído', AppColors.success(context));
      case AppointmentStatus.cancelled:
        return ('Cancelado', AppColors.error(context));
      case AppointmentStatus.rejected:
        return ('Rejeitado', AppColors.error(context));
      case AppointmentStatus.rescheduleRequested:
        return ('Reagendamento', AppColors.warning(context));
      case AppointmentStatus.noShow:
        return ('Não compareceu', AppColors.error(context));
    }
  }

  Widget _buildTopServicesSection(List<TopServiceItem> topServices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Serviços mais usados',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        if (topServices.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
            child: Center(
              child: Text(
                'Nenhum serviço este mês',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedForeground(context),
                    ),
              ),
            ),
          )
        else
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: topServices.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final s = topServices[i];
                return _topServiceCard(s);
              },
            ),
          ),
      ],
    );
  }

  Widget _topServiceCard(TopServiceItem s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      constraints: const BoxConstraints(minWidth: 140),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            s.serviceName,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${s.count} este mês',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedForeground(context),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gerenciamento',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        _menuCard(
          icon: Icons.design_services,
          title: 'Gerenciar Serviços',
          onTap: () => widget.onNavigateToPage?.call(4),
        ),
        const SizedBox(height: 12),
        _menuCard(
          icon: Icons.people,
          title: 'Gerenciar Profissionais',
          onTap: () => widget.onNavigateToPage?.call(3),
        ),
      ],
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary(context)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
