import 'package:flutter/material.dart';
import 'package:fox_link_app/modules/master/presentation/controllers/master_controller.dart';
import 'package:fox_link_app/modules/master/presentation/widgets/stats_card.dart';

class MasterPlatformUsagePage extends StatefulWidget {
  final MasterController controller;

  const MasterPlatformUsagePage({super.key, required this.controller});

  @override
  State<MasterPlatformUsagePage> createState() => _MasterPlatformUsagePageState();
}

class _MasterPlatformUsagePageState extends State<MasterPlatformUsagePage> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadPlatformStats();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (widget.controller.loading && widget.controller.platformStats == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final s = widget.controller.platformStats;
        if (s == null) {
          return const Center(child: Text('Nenhum dado disponível'));
        }
        return RefreshIndicator(
      onRefresh: () => widget.controller.loadPlatformStats(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                MasterStatsCard(
                  label: 'Agendamentos hoje',
                  value: '${s.appointmentsToday}',
                  icon: Icons.calendar_today,
                ),
                MasterStatsCard(
                  label: 'Agendamentos no mês',
                  value: '${s.appointmentsMonth}',
                  icon: Icons.calendar_month,
                ),
                MasterStatsCard(
                  label: 'Profissionais ativos',
                  value: '${s.activeProfessionals}',
                  icon: Icons.people,
                ),
                MasterStatsCard(
                  label: 'Tenants ativos',
                  value: '${s.activeTenants}',
                  icon: Icons.business,
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (s.topServices.isNotEmpty) ...[
              Text(
                'Serviços mais usados',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: s.topServices.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final e = s.topServices.entries.elementAt(i);
                    return ListTile(
                      title: Text('Serviço ${e.key}'),
                      trailing: Text('${e.value} agendamentos'),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
      },
    );
  }
}
