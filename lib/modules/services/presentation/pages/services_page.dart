import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/core/config/plan_config.dart';
import 'package:fox_link_app/modules/services/infra/datasources/service_remote_datasource.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final _serviceRemote = getIt<ServiceRemoteDataSource>();

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  int currentCount = 0;
  int maxAllowed = 0;
  String currentPlan = "";

  @override
  void initState() {
    super.initState();
    _loadLimits();
  }

  Future<void> _loadLimits() async {
    currentPlan = await _serviceRemote.getCurrentPlan();
    currentCount = await _serviceRemote.getCurrentCount();
    maxAllowed = PlanConfig.maxServices(currentPlan);
    setState(() {});
  }

  Future<void> _createService() async {
    try {
      await _serviceRemote.createService(
        _nameController.text.trim(),
        double.parse(_priceController.text),
      );

      _nameController.clear();
      _priceController.clear();
      await _loadLimits();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _delete(String id) async {
    await _serviceRemote.deleteService(id);
    await _loadLimits();
  }

  @override
  Widget build(BuildContext context) {
    final reachedLimit = currentCount >= maxAllowed;

    return Scaffold(
      appBar: AppBar(title: const Text("Serviços")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Plano: $currentPlan | $currentCount / $maxAllowed usados",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration:
                    const InputDecoration(labelText: "Nome"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    decoration:
                    const InputDecoration(labelText: "Preço"),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: reachedLimit ? null : _createService,
                  child: const Text("Adicionar"),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _serviceRemote.streamServices(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, index) {
                    final doc = docs[index];

                    return ListTile(
                      title: Text(doc['name']),
                      subtitle:
                      Text("R\$ ${doc['price']}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _delete(doc.id),
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