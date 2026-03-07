import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/shared/widgets/dashboard_card.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _period = 'Semana';

  static const _periods = ['Hoje', 'Semana', 'Mês', 'Ano'];

  // Mock data
  static const _weeklyLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  static const _weeklyValues = [1200.0, 1800.0, 900.0, 2200.0, 1500.0, 0.0, 0.0];
  static const _topProfessionals = [
    ('Maria Silva', 4500.0, 0.35),
    ('João Santos', 3200.0, 0.25),
    ('Ana Costa', 2800.0, 0.22),
  ];

  double get _maxWeekly => _weeklyValues.reduce(math.max).toDouble();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                    onSelected: (_) => setState(() => _period = label),
                    selectedColor: AppColors.accent(context),
                    checkmarkColor: AppColors.accentForeground(context),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

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
                      value: 'R\$ 9.600',
                      subtitle: 'no período',
                      icon: Icons.attach_money,
                      iconColor: AppColors.primary(context),
                      trend: '+12%',
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: DashboardCard(
                      label: 'Agendamentos',
                      value: '84',
                      subtitle: 'realizados',
                      icon: Icons.calendar_today,
                      iconColor: AppColors.primary(context),
                      trend: '+8%',
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: DashboardCard(
                      label: 'Novos clientes',
                      value: '12',
                      subtitle: 'cadastrados',
                      icon: Icons.person_add,
                      iconColor: AppColors.success(context),
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: DashboardCard(
                      label: 'Ticket médio',
                      value: 'R\$ 114',
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
                      final h = _maxWeekly > 0
                          ? (_weeklyValues[i] / _maxWeekly) * 80
                          : 0.0;
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
                  final (name, value, pct) = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            Text(
                              'R\$ ${value.toStringAsFixed(0)}',
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
      ),
    );
  }
}
