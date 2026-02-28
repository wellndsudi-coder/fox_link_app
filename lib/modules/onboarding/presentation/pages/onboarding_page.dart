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
  State<OnboardingPage> createState() =>
      _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _userRemote = GetIt.I<UserRemoteDataSource>();
  final _tenantRemote = GetIt.I<TenantRemoteDataSource>();
  final _session = GetIt.I<TenantSession>();

  final _nameController = TextEditingController();
  final _salonNameController = TextEditingController();

  String selectedType = 'admin';
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
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          "Configuração Inicial",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  "Como você deseja usar o Fox Link?",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 24),

                RadioListTile<String>(
                  activeColor: const Color(0xFF3B82F6),
                  value: 'admin',
                  groupValue: selectedType,
                  title: const Text(
                    "Criar meu Salão",
                    style: TextStyle(color: Colors.white),
                  ),
                  onChanged: (value) {
                    setState(() {
                      selectedType = value!;
                    });
                  },
                ),

                RadioListTile<String>(
                  activeColor: const Color(0xFF3B82F6),
                  value: 'client',
                  groupValue: selectedType,
                  title: const Text(
                    "Entrar como Cliente",
                    style: TextStyle(color: Colors.white),
                  ),
                  onChanged: (value) {
                    setState(() {
                      selectedType = value!;
                    });
                  },
                ),

                const SizedBox(height: 20),

                _inputField(_nameController, "Seu Nome"),

                const SizedBox(height: 20),

                if (selectedType == 'admin')
                  _inputField(
                      _salonNameController,
                      "Nome do Salão"),

                if (selectedType == 'client')
                  FutureBuilder(
                    future: _tenantRemote.getAllTenants(),
                    builder: (context, snapshot) {

                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        );
                      }

                      final tenants =
                      snapshot.data as List<Map<String, dynamic>>;

                      if (tenants.isEmpty) {
                        return const Text(
                          "Nenhum salão disponível no momento.",
                          style: TextStyle(color: Colors.white70),
                        );
                      }

                      return DropdownButtonFormField<String>(
                        dropdownColor:
                        const Color(0xFF1E293B),
                        value: selectedTenantId,
                        style:
                        const TextStyle(color: Colors.white),
                        items: tenants
                            .map<DropdownMenuItem<String>>(
                                (tenant) {
                              return DropdownMenuItem<String>(
                                value: tenant['id'] as String,
                                child: Text(
                                  tenant['name'] as String,
                                  style: const TextStyle(
                                      color: Colors.white),
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedTenantId = value;
                          });
                        },
                        decoration:
                        _inputDecoration("Escolha o Salão"),
                      );
                    },
                  ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                    isLoading ? null : _finish,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient:
                        const LinearGradient(
                          colors: [
                            Color(0xFF3B82F6),
                            Color(0xFF8B5CF6),
                          ],
                        ),
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: isLoading
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : const Text(
                          "Finalizar",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(
      TextEditingController controller,
      String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle:
      const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF334155),
      border: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}