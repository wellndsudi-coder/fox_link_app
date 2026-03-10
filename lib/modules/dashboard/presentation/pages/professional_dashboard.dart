import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/layout/layout_breakpoints.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/modules/scheduling/domain/repositories/scheduling_repository.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/approve_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/reject_appointment_usecase.dart';
import 'package:fox_link_app/shared/widgets/app_button.dart';
import 'package:fox_link_app/shared/widgets/app_card.dart';
import 'package:fox_link_app/shared/widgets/dashboard_card.dart';

import '../../domain/usecases/get_professional_metrics_usecase.dart';

/// Dashboard do profissional integrado ao ProfessionalShell.
class ProfessionalDashboard extends StatefulWidget {
  const ProfessionalDashboard({super.key});

  @override
  State<ProfessionalDashboard> createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> {
  final _useCase = GetIt.I<GetProfessionalMetricsUseCase>();
  final _session = GetIt.I<TenantSession>();
  final _schedulingRepo = GetIt.I<SchedulingRepository>();
  final _approveUseCase = GetIt.I<ApproveAppointmentUseCase>();
  final _rejectUseCase = GetIt.I<RejectAppointmentUseCase>();

  late Future<ProfessionalMetrics> _future;
  List<Appointment> _pendingAppointments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _useCase();
    _loadPending();
  }

  Future<void> _loadPending() async {
    final profId = _session.professionalId;
    if (profId == null) return;
    try {
      final list = await _schedulingRepo.getPendingByProfessional(profId);
      list.sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));
      if (mounted) setState(() => _pendingAppointments = list);
    } catch (_) {}
  }

  Future<void> _refresh() async {
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _refresh,
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
            padding: LayoutBreakpoints.pagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.count(
                  crossAxisCount: LayoutBreakpoints.isMobile(context) ? 1 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: LayoutBreakpoints.gridSpacing(context),
                  mainAxisSpacing: LayoutBreakpoints.gridSpacing(context),
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
                if (_pendingAppointments.isNotEmpty) ...[
                  _PendingAppointmentCard(
                    appointment: _pendingAppointments.first,
                    onApprove: () async {
                      await _approveUseCase(_pendingAppointments.first);
                      if (mounted) _loadPending();
                    },
                    onReject: () async {
                      await _rejectUseCase(_pendingAppointments.first);
                      if (mounted) _loadPending();
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                if (data.nextAppointment != null)
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Próximo Atendimento',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm')
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

class _PendingAppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingAppointmentCard({
    required this.appointment,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.warning(context).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning(context).withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: AppColors.warning(context)),
                const SizedBox(width: 8),
                Text(
                  'Agendamento pendente',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning(context),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning(context).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Pendente',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.warning(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Cliente: ${appointment.clientId}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Serviço: ${appointment.serviceId}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.mutedForeground(context),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: AppColors.mutedForeground(context)),
                const SizedBox(width: 6),
                Text(
                  DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(appointment.scheduledStart),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedForeground(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: AppColors.mutedForeground(context)),
                const SizedBox(width: 6),
                Text(
                  '${DateFormat('HH:mm').format(appointment.scheduledStart)} (${appointment.finalDuration} min)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedForeground(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Aceitar',
                    onPressed: onApprove,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Rejeitar',
                    variant: AppButtonVariant.outline,
                    onPressed: onReject,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
