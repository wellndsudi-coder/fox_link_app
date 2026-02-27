import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../domain/usecases/get_admin_metrics_usecase.dart';
import 'package:fox_link_app/modules/services/presentation/pages/admin_services_page.dart';
import 'package:fox_link_app/modules/professionals/presentation/pages/professionals_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() =>
      _AdminDashboardState();
}

class _AdminDashboardState
    extends State<AdminDashboard> {

  final _metricsUseCase =
  GetIt.I<GetAdminMetricsUseCase>();

  late Future<AdminMetrics> _future;

  @override
  void initState() {
    super.initState();
    _future = _metricsUseCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      AppBar(title: const Text("Admin Dashboard")),
      body: FutureBuilder<AdminMetrics>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final data = snapshot.data!;

          return SingleChildScrollView(
            child: Padding(
              padding:
              const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.stretch,
                children: [

                  /// 📊 MÉTRICAS
                  _card(
                    "Agendamentos Hoje",
                    data.todayAppointments
                        .toString(),
                  ),

                  _card(
                    "Pendentes",
                    data.pendingAppointments
                        .toString(),
                  ),

                  _card(
                    "Faturamento Hoje",
                    "R\$ ${data.todayRevenue.toStringAsFixed(2)}",
                  ),

                  _card(
                    "Faturamento Mês",
                    "R\$ ${data.monthRevenue.toStringAsFixed(2)}",
                  ),

                  const SizedBox(height: 24),

                  /// ⚙ GERENCIAMENTO
                  const Text(
                    "Gerenciamento",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// 🔧 GERENCIAR SERVIÇOS
                  Card(
                    child: ListTile(
                      leading: const Icon(
                          Icons.design_services),
                      title: const Text(
                          "Gerenciar Serviços"),
                      trailing: const Icon(
                          Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const AdminServicesPage(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// 👨‍💼 GERENCIAR PROFISSIONAIS
                  Card(
                    child: ListTile(
                      leading: const Icon(
                          Icons.people),
                      title: const Text(
                          "Gerenciar Profissionais"),
                      trailing: const Icon(
                          Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const ProfessionalsPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _card(String title, String value) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}