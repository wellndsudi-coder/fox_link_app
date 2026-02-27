import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/core/config/plan_config.dart';

class MasterDashboard extends StatelessWidget {
  const MasterDashboard({super.key});

  Future<Map<String, int>> _getMetrics() async {
    final tenants =
    await FirebaseFirestore.instance.collection('tenants').get();

    int active = 0;
    int trial = 0;
    int suspended = 0;

    for (var doc in tenants.docs) {
      final data = doc.data();

      if (data['status'] == 'active') active++;
      if (data['plan'] == PlanConfig.trial) trial++;
      if (data['status'] == 'suspended') suspended++;
    }

    return {
      'total': tenants.docs.length,
      'active': active,
      'trial': trial,
      'suspended': suspended,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel Master - Fox Link"),
      ),
      body: Column(
        children: [
          FutureBuilder(
            future: _getMetrics(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox();
              }

              final data = snapshot.data!;

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text("Total: ${data['total']}"),
                    Text("Ativos: ${data['active']}"),
                    Text("Trial: ${data['trial']}"),
                    Text("Suspensos: ${data['suspended']}"),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tenants')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final tenants = snapshot.data!.docs;

                if (tenants.isEmpty) {
                  return const Center(
                    child: Text("Nenhum salão cadastrado"),
                  );
                }

                return ListView.builder(
                  itemCount: tenants.length,
                  itemBuilder: (context, index) {
                    final tenant = tenants[index];
                    final data =
                    tenant.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.all(12),
                      child: ListTile(
                        title: Text(data['name'] ?? 'Sem nome'),
                        subtitle: Text(
                            "Plano: ${data['plan']} | Status: ${data['status']}"),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'activate') {
                              await FirebaseFirestore.instance
                                  .collection('tenants')
                                  .doc(tenant.id)
                                  .update({'status': 'active'});
                            } else if (value == 'suspend') {
                              await FirebaseFirestore.instance
                                  .collection('tenants')
                                  .doc(tenant.id)
                                  .update({'status': 'suspended'});
                            } else if (value == PlanConfig.trial ||
                                value == PlanConfig.basic ||
                                value == PlanConfig.plus ||
                                value == PlanConfig.pro ||
                                value == PlanConfig.unlimited) {
                              await FirebaseFirestore.instance
                                  .collection('tenants')
                                  .doc(tenant.id)
                                  .update({'plan': value});
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                                value: 'activate',
                                child: Text("Ativar")),
                            PopupMenuItem(
                                value: 'suspend',
                                child: Text("Suspender")),
                            PopupMenuItem(
                                value: PlanConfig.trial,
                                child: Text("Plano Trial")),
                            PopupMenuItem(
                                value: PlanConfig.basic,
                                child: Text("Plano Basic")),
                            PopupMenuItem(
                                value: PlanConfig.plus,
                                child: Text("Plano Plus")),
                            PopupMenuItem(
                                value: PlanConfig.pro,
                                child: Text("Plano Pro")),
                            PopupMenuItem(
                                value: PlanConfig.unlimited,
                                child: Text("Plano Unlimited")),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}