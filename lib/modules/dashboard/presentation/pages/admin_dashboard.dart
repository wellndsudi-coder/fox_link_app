import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../domain/usecases/get_admin_metrics_usecase.dart';
import 'package:fox_link_app/modules/services/presentation/pages/admin_services_page.dart';
import 'package:fox_link_app/modules/professionals/presentation/pages/professionals_page.dart';

import 'package:fox_link_app/shared/widgets/app_card.dart';
import 'package:fox_link_app/shared/widgets/app_section_title.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _metricsUseCase = GetIt.I<GetAdminMetricsUseCase>();

  late Future<AdminMetrics> _future;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _future = _metricsUseCase();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          )
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<AdminMetrics>(
          future: _future,
          builder: (context, snapshot) {

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text("Erro ao carregar métricas"),
              );
            }

            final data = snapshot.data!;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const AppSectionTitle(
                    title: "Resumo Geral",
                    subtitle: "Visão estratégica do negócio",
                  ),

                  const SizedBox(height: 16),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [

                      _metricCard(
                        "Agendamentos Hoje",
                        data.todayAppointments.toString(),
                        Icons.calendar_today,
                        Colors.blue,
                      ),

                      _metricCard(
                        "Pendentes",
                        data.pendingAppointments.toString(),
                        Icons.pending,
                        Colors.orange,
                      ),

                      _metricCard(
                        "Faturamento Hoje",
                        "R\$ ${data.todayRevenue.toStringAsFixed(2)}",
                        Icons.attach_money,
                        Colors.green,
                      ),

                      _metricCard(
                        "Faturamento Mês",
                        "R\$ ${data.monthRevenue.toStringAsFixed(2)}",
                        Icons.trending_up,
                        Colors.purple,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  const AppSectionTitle(
                    title: "Gerenciamento",
                    subtitle: "Controle operacional",
                  ),

                  const SizedBox(height: 16),

                  _menuCard(
                    icon: Icons.design_services,
                    title: "Gerenciar Serviços",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminServicesPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  _menuCard(
                    icon: Icons.people,
                    title: "Gerenciar Profissionais",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfessionalsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _metricCard(
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Icon(icon, color: color),

          const SizedBox(height: 12),

          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
          ),

          const SizedBox(height: 4),

          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
          ),
        ],
      ),
    );
  }
}