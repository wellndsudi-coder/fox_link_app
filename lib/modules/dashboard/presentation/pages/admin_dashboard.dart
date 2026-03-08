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
import '../../domain/usecases/get_weekly_appointments_usecase.dart';
import '../../domain/usecases/get_tenant_weekly_occupation_usecase.dart';
import '../widgets/admin_dashboard_header.dart';
import '../widgets/today_overview_card.dart';
import '../widgets/quick_actions_section.dart';
import '../widgets/weekly_occupancy_card.dart';
import '../widgets/smart_insights_section.dart';
import 'package:fox_link_app/shared/widgets/appointment_card.dart';
import 'package:fox_link_app/shared/widgets/dashboard_card.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';

enum WeeklyChartMode { revenue, appointments }

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
  final _weeklyAppointmentsUseCase = GetIt.I<GetWeeklyAppointmentsUseCase>();
  final _weeklyOccupationUseCase = GetIt.I<GetTenantWeeklyOccupationUseCase>();

  WeeklyChartMode _chartMode = WeeklyChartMode.revenue;

  late Future<({
    AdminMetrics metrics,
    List<TodayAppointmentDisplay> agenda,
    List<TopServiceItem> topServices,
    List<DailyRevenue> weeklyRevenue,
    List<DailyAppointmentCount> weeklyAppointments,
    List<DayOccupation> weeklyOccupation,
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
        _weeklyAppointmentsUseCase(),
        _weeklyOccupationUseCase(),
      ]).then((results) => (
            metrics: results[0] as AdminMetrics,
            agenda: results[1] as List<TodayAppointmentDisplay>,
            topServices: results[2] as List<TopServiceItem>,
            weeklyRevenue: results[3] as List<DailyRevenue>,
            weeklyAppointments: results[4] as List<DailyAppointmentCount>,
            weeklyOccupation: results[5] as List<DayOccupation>,
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

  List<TodayAppointmentDisplay> _sortAgendaByTime(List<TodayAppointmentDisplay> agenda) {
    final sorted = List<TodayAppointmentDisplay>.from(agenda);
    sorted.sort((a, b) => a.time.compareTo(b.time));
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: FutureBuilder<
          ({
        AdminMetrics metrics,
        List<TodayAppointmentDisplay> agenda,
        List<TopServiceItem> topServices,
        List<DailyRevenue> weeklyRevenue,
        List<DailyAppointmentCount> weeklyAppointments,
        List<DayOccupation> weeklyOccupation,
      })>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar métricas'));
          }

          final data = snapshot.data!;
          final sortedAgenda = _sortAgendaByTime(data.agenda);

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminDashboardHeader(
                  userName: _getUserName(),
                  appointmentsToday: data.metrics.totalSlots,
                  onRefresh: _loadData,
                ),
                const SizedBox(height: 16),

                TodayOverviewCard(
                  appointmentsToday: data.metrics.totalSlots,
                  totalSlots: data.metrics.totalSlots,
                ),
                const SizedBox(height: 24),

                _buildMetricsGrid(data.metrics),
                const SizedBox(height: 24),

                _buildWeeklyChart(
                  weeklyRevenue: data.weeklyRevenue,
                  weeklyAppointments: data.weeklyAppointments,
                ),
                const SizedBox(height: 24),

                _buildUpcomingAppointments(sortedAgenda),
                const SizedBox(height: 24),

                QuickActionsSection(onNavigateToPage: widget.onNavigateToPage),
                const SizedBox(height: 24),

                _buildTopServicesSection(data.topServices),
                const SizedBox(height: 24),

                WeeklyOccupancyCard(data: data.weeklyOccupation),
                const SizedBox(height: 24),

                SmartInsightsSection(
                  metrics: data.metrics,
                  totalSlots: data.metrics.totalSlots,
                ),
                const SizedBox(height: 24),

                _buildManagementShortcuts(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeeklyChart({
    required List<DailyRevenue> weeklyRevenue,
    required List<DailyAppointmentCount> weeklyAppointments,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Desempenho semanal',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<WeeklyChartMode>(
          segments: const [
            ButtonSegment(
              value: WeeklyChartMode.revenue,
              label: Text('Faturamento'),
            ),
            ButtonSegment(
              value: WeeklyChartMode.appointments,
              label: Text('Agendamentos'),
            ),
          ],
          selected: {_chartMode},
          onSelectionChanged: (s) => setState(() => _chartMode = s.first),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _chartMode == WeeklyChartMode.revenue
                ? _buildRevenueChart(weeklyRevenue)
                : _buildAppointmentsChart(weeklyAppointments),
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueChart(List<DailyRevenue> weeklyRevenue) {
    final theme = Theme.of(context);
    final maxY = weeklyRevenue.isEmpty
        ? 100.0
        : (weeklyRevenue
                    .map((d) => d.revenue)
                    .reduce((a, b) => a > b ? a : b) *
                1.2)
            .clamp(10.0, double.infinity);

    if (weeklyRevenue.isEmpty) {
      return Center(
        child: Text(
          'Sem dados de faturamento',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.mutedForeground(context),
          ),
        ),
      );
    }

    return BarChart(
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
                      DateFormat('dd/MM')
                          .format(weeklyRevenue[i].date),
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
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
            showingTooltipIndicators: [],
          );
        }).toList(),
      ),
      swapAnimationDuration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildAppointmentsChart(List<DailyAppointmentCount> weeklyAppointments) {
    final theme = Theme.of(context);
    final maxY = weeklyAppointments.isEmpty
        ? 10.0
        : (weeklyAppointments
                    .map((d) => d.count.toDouble())
                    .reduce((a, b) => a > b ? a : b) *
                1.2)
            .clamp(1.0, double.infinity);

    if (weeklyAppointments.isEmpty) {
      return Center(
        child: Text(
          'Sem dados de agendamentos',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.mutedForeground(context),
          ),
        ),
      );
    }

    final spots = weeklyAppointments
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble()))
        .toList();

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(enabled: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.border(context),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i >= 0 && i < weeklyAppointments.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('dd/MM')
                          .format(weeklyAppointments[i].date),
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
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (weeklyAppointments.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildMetricsGrid(AdminMetrics metrics) {
    final crossAxisCount =
        MediaQuery.of(context).size.width > 600 ? 4 : 2;

    return GridView.count(
      crossAxisCount: crossAxisCount,
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

  Widget _buildUpcomingAppointments(
      List<TodayAppointmentDisplay> agenda) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Próximos agendamentos',
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
          _emptyState('Nenhum agendamento hoje')
        else
          ...agenda.take(5).map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _appointmentCardFromDisplay(context, a),
              )),
      ],
    );
  }

  Widget _appointmentCardFromDisplay(
      BuildContext context, TodayAppointmentDisplay d) {
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

  (String, Color) _statusLabelAndColor(
      BuildContext context, AppointmentStatus status) {
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
      case AppointmentStatus.waitingList:
        return ('Lista de espera', AppColors.mutedForeground(context));
    }
  }

  Widget _buildTopServicesSection(List<TopServiceItem> topServices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Serviços mais usados este mês',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        if (topServices.isEmpty)
          _emptyState('Nenhum serviço este mês')
        else
          ...topServices.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.border(context)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.serviceName,
                        style:
                            Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        '${s.count} reservas',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color:
                                  AppColors.mutedForeground(context),
                            ),
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  Widget _emptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedForeground(context),
              ),
        ),
      ),
    );
  }

  Widget _buildManagementShortcuts() {
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
        const SizedBox(height: 12),
        _menuCard(
          icon: Icons.person,
          title: 'Gerenciar Clientes',
          onTap: () => widget.onNavigateToPage?.call(2),
        ),
        const SizedBox(height: 12),
        _menuCard(
          icon: Icons.calendar_month,
          title: 'Gerenciar Agenda',
          onTap: () => widget.onNavigateToPage?.call(1),
        ),
      ],
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(context)),
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
      ),
    );
  }
}
