import 'package:flutter/material.dart';
import '../controllers/subscription_controller.dart';
import '../widgets/tenant_status_badge.dart';

class MasterSubscriptionsPage extends StatefulWidget {
  final SubscriptionController controller;

  const MasterSubscriptionsPage({super.key, required this.controller});

  @override
  State<MasterSubscriptionsPage> createState() => _MasterSubscriptionsPageState();
}

class _MasterSubscriptionsPageState extends State<MasterSubscriptionsPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadSubscriptions();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (widget.controller.loading && widget.controller.subscriptions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final subs = widget.controller.subscriptions;
        return RefreshIndicator(
          onRefresh: () => widget.controller.loadSubscriptions(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Card(
              child: subs.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('Nenhuma assinatura encontrada')),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Tenant')),
                          DataColumn(label: Text('Plano')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Início')),
                          DataColumn(label: Text('Renovação')),
                          DataColumn(label: Text('Valor')),
                        ],
                        rows: subs.map((s) {
                          return DataRow(cells: [
                            DataCell(Text(s.tenantName)),
                            DataCell(Text(_planLabel(s.plan))),
                            DataCell(TenantStatusBadge(status: s.status)),
                            DataCell(Text(_fmt(s.startDate))),
                            DataCell(Text(s.renewalDate != null ? _fmt(s.renewalDate!) : '-')),
                            DataCell(Text('R\$ ${s.value.toStringAsFixed(2).replaceAll('.', ',')}')),
                          ]);
                        }).toList(),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  String _planLabel(String p) {
    final m = {'basic': 'Basic', 'pro': 'Pro', 'premium': 'Premium'};
    return m[p] ?? p;
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
