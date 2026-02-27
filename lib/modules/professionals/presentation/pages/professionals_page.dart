import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/core/config/plan_config.dart';
import 'package:fox_link_app/modules/professionals/infra/datasources/professional_remote_datasource.dart';

class ProfessionalsPage extends StatefulWidget {
  const ProfessionalsPage({super.key});

  @override
  State<ProfessionalsPage> createState() =>
      _ProfessionalsPageState();
}

class _ProfessionalsPageState
    extends State<ProfessionalsPage> {
  final _professionalRemote =
  getIt<ProfessionalRemoteDataSource>();

  final _nameController =
  TextEditingController();
  final _emailController =
  TextEditingController(); // 🔥 NOVO

  int currentCount = 0;
  int maxAllowed = 0;
  String currentPlan = "";

  @override
  void initState() {
    super.initState();
    _loadLimits();
  }

  Future<void> _loadLimits() async {
    currentPlan =
    await _professionalRemote.getCurrentPlan();
    currentCount =
    await _professionalRemote.getCurrentCount();
    maxAllowed =
        PlanConfig.maxProfessionals(currentPlan);

    setState(() {});
  }

  Future<void> _createProfessional() async {
    try {
      final name =
      _nameController.text.trim();
      final email =
      _emailController.text.trim();

      if (name.isEmpty ||
          email.isEmpty) {
        throw Exception(
            "Nome e email são obrigatórios.");
      }

      await _professionalRemote
          .createProfessional(
        name: name,
        email: email,
      );

      _nameController.clear();
      _emailController.clear();

      await _loadLimits();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
          Text("Convite enviado com sucesso"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _delete(String id) async {
    await _professionalRemote
        .deleteProfessional(id);
    await _loadLimits();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profissionais"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          Padding(
            padding:
            const EdgeInsets.all(16),
            child: Text(
              "Plano: $currentPlan | $currentCount / $maxAllowed usados",
              style: const TextStyle(
                  fontWeight:
                  FontWeight.bold),
            ),
          ),

          Padding(
            padding:
            const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller:
                  _nameController,
                  decoration:
                  const InputDecoration(
                    labelText:
                    "Nome do Profissional",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller:
                  _emailController,
                  decoration:
                  const InputDecoration(
                    labelText:
                    "Email do Profissional",
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                    _createProfessional,
                    child: const Text(
                        "Enviar Convite"),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<
                QuerySnapshot>(
              stream: _professionalRemote
                  .streamProfessionals(),
              builder:
                  (context, snapshot) {
                if (!snapshot
                    .hasData) {
                  return const Center(
                    child:
                    CircularProgressIndicator(),
                  );
                }

                final docs =
                    snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                        "Nenhum profissional cadastrado"),
                  );
                }

                return ListView.builder(
                  itemCount:
                  docs.length,
                  itemBuilder:
                      (_, index) {
                    final doc =
                    docs[index];

                    return ListTile(
                      title:
                      Text(doc['name']),
                      subtitle: doc[
                      'email'] !=
                          null
                          ? Text(
                          doc['email'])
                          : null,
                      trailing:
                      IconButton(
                        icon: const Icon(
                            Icons.delete),
                        onPressed: () =>
                            _delete(
                                doc.id),
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