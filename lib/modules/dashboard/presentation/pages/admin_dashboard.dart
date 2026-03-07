import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../domain/usecases/get_admin_metrics_usecase.dart';
import '../../domain/usecases/get_today_agenda_usecase.dart';
import '../../domain/usecases/get_top_services_usecase.dart';
import 'package:fox_link_app/shared/widgets/app_header.dart';
import 'package:fox_link_app/shared/widgets/appointment_card.dart';
import 'package:fox_link_app/shared/widgets/dashboard_card.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';

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

  late Future<({AdminMetrics metrics, List<TodayAppointmentDisplay> agenda, List<TopServiceItem> topServices})> _future;

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
      ]).then((results) => (
            metrics: results[0] as AdminMetrics,
            agenda: results[1] as List<TodayAppointmentDisplay>,
            topServices: results[2] as List<TopServiceItem>,
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
          ({AdminMetrics metrics, List<TodayAppointmentDisplay> agenda, List<TopServiceItem> topServices})>(
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
          iconColor: AppTheme.primaryColor,
        ),
        DashboardCard(
          label: 'Clientes',
          value: metrics.clientsServed.toString(),
          subtitle: 'Atendidos',
          icon: Icons.people,
          iconColor: const Color(0xFF8B5CF6),
        ),
        DashboardCard(
          label: 'Faturamento',
          value: 'R\$ ${metrics.todayRevenue.toStringAsFixed(2)}',
          subtitle: 'Hoje',
          trend: metrics.revenueTrend,
          icon: Icons.attach_money,
          iconColor: AppTheme.successColor,
        ),
        DashboardCard(
          label: 'Serviços',
          value: metrics.servicesCompleted.toString(),
          subtitle: 'Realizados',
          icon: Icons.design_services,
          iconColor: const Color(0xFF0EA5E9),
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
                      color: const Color(0xFF64748B),
                    ),
              ),
            ),
          )
        else
          ...agenda.take(5).map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _appointmentCardFromDisplay(a),
              )),
      ],
    );
  }

  Widget _appointmentCardFromDisplay(TodayAppointmentDisplay d) {
    final (label, color) = _statusLabelAndColor(d.status);
    return AppointmentCard(
      clientName: d.clientName,
      statusLabel: label,
      statusColor: color,
      time: d.time,
      serviceName: d.serviceName,
      professionalName: d.professionalName,
    );
  }

  (String, Color) _statusLabelAndColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.approved:
        return ('Confirmado', AppTheme.successColor);
      case AppointmentStatus.pending:
        return ('Pendente', AppTheme.warningColor);
      case AppointmentStatus.completed:
        return ('Concluído', AppTheme.successColor);
      case AppointmentStatus.cancelled:
        return ('Cancelado', AppTheme.errorColor);
      case AppointmentStatus.rejected:
        return ('Rejeitado', AppTheme.errorColor);
      case AppointmentStatus.rescheduleRequested:
        return ('Reagendamento', AppTheme.warningColor);
      case AppointmentStatus.noShow:
        return ('Não compareceu', AppTheme.errorColor);
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
                      color: const Color(0xFF64748B),
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
            color: Colors.black.withValues(alpha: 0.04),
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
                  color: const Color(0xFF64748B),
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
            Icon(icon, color: AppTheme.primaryColor),
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
