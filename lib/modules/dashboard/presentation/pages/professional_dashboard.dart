import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:fox_link_app/shared/widgets/app_card.dart';
import 'package:fox_link_app/modules/professionals/presentation/pages/professional_panel.dart'; // 🔥 ADICIONADO

import '../../domain/usecases/get_professional_metrics_usecase.dart';

class ProfessionalDashboard extends StatefulWidget {
  const ProfessionalDashboard({super.key});

  @override
  State<ProfessionalDashboard> createState() =>
      _ProfessionalDashboardState();
}

class _ProfessionalDashboardState
    extends State<ProfessionalDashboard> {

  final _useCase =
  GetIt.I<GetProfessionalMetricsUseCase>();

  late Future<ProfessionalMetrics> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _useCase();
  }

  Future<void> _refresh() async {
    setState(() {
      _load();
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
        title: const Text("Meu Painel"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<ProfessionalMetrics>(
          future: _future,
          builder: (context, snapshot) {

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text("Erro ao carregar dados"),
              );
            }

            final data = snapshot.data!;

            final occupancy = data.totalSlots == 0
                ? 0
                : (data.todayAppointments /
                data.totalSlots) *
                100;

            return SingleChildScrollView(
              physics:
              const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics:
                    const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [

                      _metricCard(
                        "Hoje",
                        data.todayAppointments
                            .toString(),
                        Icons.calendar_today,
                        Colors.blue,
                      ),

                      _metricCard(
                        "Receita Hoje",
                        "R\$ ${data.todayRevenue.toStringAsFixed(2)}",
                        Icons.attach_money,
                        Colors.green,
                      ),

                      _metricCard(
                        "Receita Mês",
                        "R\$ ${data.monthRevenue.toStringAsFixed(2)}",
                        Icons.trending_up,
                        Colors.purple,
                      ),

                      _metricCard(
                        "Ocupação",
                        "${occupancy.toStringAsFixed(1)}%",
                        Icons.pie_chart,
                        Colors.teal,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  if (data.nextAppointment != null)
                    AppCard(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Próximo Atendimento",
                            style: TextStyle(
                                fontWeight:
                                FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat(
                                "dd/MM/yyyy HH:mm")
                                .format(data
                                .nextAppointment!),
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // 🔥 CORREÇÃO AQUI
                  AppCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const ProfessionalPanel(),
                        ),
                      );
                    },
                    child: Row(
                      children: const [
                        Icon(Icons.schedule),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                              "Abrir Painel Completo"),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                        ),
                      ],
                    ),
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
        crossAxisAlignment:
        CrossAxisAlignment.start,
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
            style: Theme.of(context)
                .textTheme
                .headlineMedium,
          ),
        ],
      ),
    );
  }
}