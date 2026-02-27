import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/users/infra/datasources/user_remote_datasource.dart';
import 'package:fox_link_app/modules/tenant/infra/datasources/tenant_remote_datasource.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/admin_dashboard.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/client_dashboard.dart';

class OnboardingPage extends StatefulWidget {
  final String uid;
  final String email;

  const OnboardingPage({
    super.key,
    required this.uid,
    required this.email,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _userRemote = GetIt.I<UserRemoteDataSource>();
  final _tenantRemote = GetIt.I<TenantRemoteDataSource>();
  final _session = GetIt.I<TenantSession>();

  final _nameController = TextEditingController();
  final _salonNameController = TextEditingController();

  String selectedType = 'admin'; // admin ou client
  String? selectedTenantId;

  bool isLoading = false;

  Future<void> _finish() async {
    if (_nameController.text.trim().isEmpty) {
      _showError("Informe seu nome");
      return;
    }

    if (selectedType == 'admin' &&
        _salonNameController.text.trim().isEmpty) {
      _showError("Informe o nome do salão");
      return;
    }

    if (selectedType == 'client' && selectedTenantId == null) {
      _showError("Escolha um salão");
      return;
    }

    setState(() => isLoading = true);

    try {
      if (selectedType == 'admin') {
        /// 🏢 CRIAR SALÃO
        final tenantId = await _tenantRemote.createTenant(
          name: _salonNameController.text.trim(),
          ownerId: widget.uid,
        );

        await _userRemote.createUser(
          uid: widget.uid,
          email: widget.email,
          role: 'admin',
          tenantId: tenantId,
        );

        _session.setSession(
          tenantId: tenantId,
          role: 'admin',
          uid: widget.uid,
          email: widget.email,
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => const AdminDashboard()),
        );
      } else {
        /// 👤 CRIAR CLIENTE
        await _userRemote.createUser(
          uid: widget.uid,
          email: widget.email,
          role: 'client',
          tenantId: selectedTenantId!,
        );

        _session.setSession(
          tenantId: selectedTenantId!,
          role: 'client',
          uid: widget.uid,
          email: widget.email,
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => const ClientDashboard()),
        );
      }
    } catch (e) {
      _showError(e.toString());
    }

    setState(() => isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configuração Inicial")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const Text(
              "Você deseja:",
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            /// 🏢 Criar Salão
            RadioListTile<String>(
              value: 'admin',
              groupValue: selectedType,
              title: const Text("Criar meu Salão"),
              onChanged: (value) {
                setState(() {
                  selectedType = value!;
                });
              },
            ),

            /// 👤 Criar Cliente
            RadioListTile<String>(
              value: 'client',
              groupValue: selectedType,
              title: const Text("Entrar como Cliente"),
              onChanged: (value) {
                setState(() {
                  selectedType = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration:
              const InputDecoration(labelText: "Seu Nome"),
            ),

            const SizedBox(height: 20),

            /// 🏢 Campo Nome do Salão
            if (selectedType == 'admin')
              TextField(
                controller: _salonNameController,
                decoration: const InputDecoration(
                    labelText: "Nome do Salão"),
              ),

            /// 👤 Dropdown Salões
            if (selectedType == 'client')
              FutureBuilder(
                future: _tenantRemote.getAllTenants(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    );
                  }

                  final tenants =
                  snapshot.data as List<Map<String, dynamic>>;

                  if (tenants.isEmpty) {
                    return const Text(
                        "Nenhum salão disponível no momento.");
                  }

                  return DropdownButtonFormField<String>(
                    value: selectedTenantId,
                    items: tenants
                        .map<DropdownMenuItem<String>>(
                            (tenant) {
                          final id = tenant['id'] as String;
                          final name =
                          tenant['name'] as String;

                          return DropdownMenuItem<String>(
                            value: id,
                            child: Text(name),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedTenantId = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: "Escolha o Salão",
                    ),
                  );
                },
              ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: isLoading ? null : _finish,
              child: isLoading
                  ? const CircularProgressIndicator(
                color: Colors.white,
              )
                  : const Text("Finalizar"),
            ),
          ],
        ),
      ),
    );
  }
}