import 'package:flutter/material.dart';
import 'package:fox_link_app/modules/master/presentation/controllers/master_controller.dart';
import 'package:fox_link_app/modules/master/presentation/widgets/stats_card.dart';

class MasterFinancialPage extends StatefulWidget {
  final MasterController controller;

  const MasterFinancialPage({super.key, required this.controller});

  @override
  State<MasterFinancialPage> createState() => _MasterFinancialPageState();
}

class _MasterFinancialPageState extends State<MasterFinancialPage> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await widget.controller.loadFinancialStats();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (widget.controller.loading && widget.controller.financialStats == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final s = widget.controller.financialStats;
        if (s == null) {
          return const Center(child: Text('Nenhum dado disponível'));
        }
        return RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                MasterStatsCard(
                  label: 'MRR',
                  value: 'R\$ ${s.mrr.toStringAsFixed(2).replaceAll('.', ',')}',
                  icon: Icons.trending_up,
                ),
                MasterStatsCard(
                  label: 'Receita total',
                  value: 'R\$ ${s.totalRevenue.toStringAsFixed(2).replaceAll('.', ',')}',
                  icon: Icons.attach_money,
                ),
                MasterStatsCard(
                  label: 'Cancelamentos',
                  value: '${s.cancellations}',
                  icon: Icons.cancel,
                ),
                MasterStatsCard(
                  label: 'Ticket médio',
                  value: 'R\$ ${s.averageTicket.toStringAsFixed(2).replaceAll('.', ',')}',
                  icon: Icons.receipt,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
