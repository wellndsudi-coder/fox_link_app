import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_admin_metrics_usecase.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_weekly_revenue_usecase.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_top_services_usecase.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_top_professionals_usecase.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_client_retention_usecase.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_occupancy_rate_usecase.dart';
import 'package:fox_link_app/shared/widgets/dashboard_card.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _period = 'Semana';

  static const _periods = ['Hoje', 'Semana', 'Mês', 'Ano'];

  static const _weeklyLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  final _metricsUseCase = GetIt.I<GetAdminMetricsUseCase>();
  final _weeklyRevenueUseCase = GetIt.I<GetWeeklyRevenueUseCase>();
  final _topServicesUseCase = GetIt.I<GetTopServicesUseCase>();
  final _topProfessionalsUseCase = GetIt.I<GetTopProfessionalsUseCase>();
  final _retentionUseCase = GetIt.I<GetClientRetentionUseCase>();
  final _occupancyUseCase = GetIt.I<GetOccupancyRateUseCase>();

  AdminMetrics? _metrics;
  List<DailyRevenue> _weeklyRevenue = [];
  List<TopServiceItem> _topServices = [];
  List<TopProfessionalItem> _topProfessionals = [];
  int _retentionCount = 0;
  double _occupancyRate = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final metrics = await _metricsUseCase();
      final weekly = await _weeklyRevenueUseCase();
      final services = await _topServicesUseCase(limit: 5);
      final daysBack = _period == 'Semana' ? 7 : _period == 'Mês' ? 30 : _period == 'Ano' ? 365 : 1;
      final profs = await _topProfessionalsUseCase(limit: 5, daysBack: daysBack);
      final retention = await _retentionUseCase(daysBack: daysBack);
      final occupancy = await _occupancyUseCase(daysBack: daysBack);
      if (mounted) {
        setState(() {
          _metrics = metrics;
          _weeklyRevenue = weekly;
          _topServices = services;
          _topProfessionals = profs;
          _retentionCount = retention;
          _occupancyRate = occupancy;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _periods.map((label) {
                final selected = _period == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _period = label);
                      _load();
                    },
                    selectedColor: AppColors.accent(context),
                    checkmarkColor: AppColors.accentForeground(context),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          if (_loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ))
          else ...[
          // StatCards
          LayoutBuilder(
            builder: (_, c) {
              const gap = 12.0;
              const cols = 2;
              final w = (c.maxWidth - gap) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  SizedBox(
                    width: w,
                    child: DashboardCard(
                      label: 'Receita',
                      value: 'R\$ ${(_metrics?.monthRevenue ?? 0).toStringAsFixed(0)}',
                      subtitle: 'no mês',
                      icon: Icons.attach_money,
                      iconColor: AppColors.primary(context),
                      trend: _metrics?.revenueTrend,
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: DashboardCard(
                      label: 'Agendamentos',
                      value: '${_metrics?.servicesCompleted ?? 0}',
                      subtitle: 'hoje (concluídos)',
                      icon: Icons.calendar_today,
                      iconColor: AppColors.primary(context),
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: DashboardCard(
                      label: 'Clientes atendidos',
                      value: '${_metrics?.clientsServed ?? 0}',
                      subtitle: 'hoje',
                      icon: Icons.person_add,
                      iconColor: AppColors.success(context),
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: DashboardCard(
                      label: 'Retenção',
                      value: '$_retentionCount',
                      subtitle: 'clientes com 2+ agendamentos',
                      icon: Icons.people,
                      iconColor: AppColors.primary(context),
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: DashboardCard(
                      label: 'Taxa ocupação',
                      value: '${_occupancyRate.toStringAsFixed(1)}%',
                      subtitle: 'período',
                      icon: Icons.pie_chart,
                      iconColor: AppColors.success(context),
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: DashboardCard(
                      label: 'Ticket médio',
                      value: _metrics != null && _metrics!.servicesCompleted > 0
                          ? 'R\$ ${(_metrics!.todayRevenue / _metrics!.servicesCompleted).toStringAsFixed(0)}'
                          : 'R\$ 0',
                      subtitle: 'por atendimento',
                      icon: Icons.receipt,
                      iconColor: AppColors.warning(context),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Faturamento semanal
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FATURAMENTO SEMANAL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mutedForeground(context),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_weeklyLabels.length, (i) {
                      final rev = i < _weeklyRevenue.length
                          ? _weeklyRevenue[i].revenue
                          : 0.0;
                      final maxWeekly = _weeklyRevenue.isEmpty
                          ? 1.0
                          : _weeklyRevenue.map((r) => r.revenue).reduce(math.max);
                      final h = maxWeekly > 0 ? (rev / maxWeekly) * 80 : 0.0;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _weeklyLabels[i],
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedForeground(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 28,
                            height: math.max(4, h),
                            decoration: BoxDecoration(
                              color: AppColors.primary(context),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Top serviços
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOP SERVIÇOS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mutedForeground(context),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                if (_topServices.isEmpty)
                  Text(
                    'Nenhum serviço no período',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.mutedForeground(context),
                    ),
                  )
                else
                  ..._topServices.asMap().entries.map((e) {
                    final item = e.value;
                    final total = _topServices.fold<int>(
                        0, (s, x) => s + x.count);
                    final pct = total > 0 ? item.count / total : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.serviceName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary(context),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${item.count} agendamentos',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mutedForeground(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              backgroundColor: AppColors.fillColor(context),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Top profissionais
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOP PROFISSIONAIS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mutedForeground(context),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                ..._topProfessionals.asMap().entries.map((e) {
                  final item = e.value;
                  final total = _topProfessionals.fold<double>(
                      0, (s, x) => s + x.revenue);
                  final pct = total > 0 ? item.revenue / total : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            Text(
                              'R\$ ${item.revenue.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedForeground(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: AppColors.fillColor(context),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 32),
          ],
        ],
      ),
    ),
    );
  }
}
