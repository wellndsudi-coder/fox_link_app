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
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: FutureBuilder<AdminMetrics>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            );
          }

          final data = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [

                const Text(
                  "Resumo do Dia",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                _metricCard(
                  "Agendamentos Hoje",
                  data.todayAppointments
                      .toString(),
                ),

                _metricCard(
                  "Pendentes",
                  data.pendingAppointments
                      .toString(),
                ),

                _metricCard(
                  "Faturamento Hoje",
                  "R\$ ${data.todayRevenue.toStringAsFixed(2)}",
                ),

                _metricCard(
                  "Faturamento Mês",
                  "R\$ ${data.monthRevenue.toStringAsFixed(2)}",
                ),

                const SizedBox(height: 30),

                const Text(
                  "Gerenciamento",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                    FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                _menuCard(
                  icon: Icons.design_services,
                  title: "Gerenciar Serviços",
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

                const SizedBox(height: 16),

                _menuCard(
                  icon: Icons.people,
                  title:
                  "Gerenciar Profissionais",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        ProfessionalsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // =============================
  // 📊 CARD MÉTRICAS
  // =============================
  Widget _metricCard(
      String title, String value) {
    return Container(
      margin:
      const EdgeInsets.only(bottom: 14),
      padding:
      const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius:
        BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =============================
  // ⚙ MENU CARD
  // =============================
  Widget _menuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius:
        BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFF3B82F6),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white54,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}
