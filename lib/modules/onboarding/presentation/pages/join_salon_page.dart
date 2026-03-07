import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/modules/auth/domain/entities/onboarding_data.dart';
import 'package:fox_link_app/core/widgets/client_shell.dart';
import 'package:fox_link_app/modules/tenant/infra/datasources/tenant_remote_datasource.dart';
import 'package:fox_link_app/modules/users/infra/datasources/user_remote_datasource.dart';

class JoinSalonPage extends StatefulWidget {
  final OnboardingData data;

  const JoinSalonPage({
    super.key,
    required this.data,
  });

  @override
  State<JoinSalonPage> createState() => _JoinSalonPageState();
}

class _JoinSalonPageState extends State<JoinSalonPage> {
  final _searchController = TextEditingController();
  final _codeController = TextEditingController();

  final _tenantRemote = getIt<TenantRemoteDataSource>();
  final _userRemote = getIt<UserRemoteDataSource>();
  final _session = getIt<TenantSession>();

  String searchQuery = '';
  bool isLoadingCode = false;

  @override
  void dispose() {
    _searchController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinByTenantId(String tenantId) async {
    try {
      await _userRemote.createUser(
        uid: widget.data.uid,
        email: widget.data.email,
        role: 'client',
        tenantId: tenantId,
        name: widget.data.name,
        phone: widget.data.phone,
      );

      _session.setSession(
        tenantId: tenantId,
        role: 'client',
        uid: widget.data.uid,
        email: widget.data.email,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ClientShell(),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _joinByCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o código do salão.')),
      );
      return;
    }

    setState(() => isLoadingCode = true);

    try {
      final tenantDoc = await _tenantRemote.getTenantByInviteCode(code);

      if (tenantDoc == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Código inválido ou salão não encontrado.')),
          );
        }
        return;
      }

      await _joinByTenantId(tenantDoc.id);
    } finally {
      if (mounted) {
        setState(() => isLoadingCode = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text('Entrar em um salão'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Buscar salão',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Nome do salão',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('tenants')
                    .where('status', isEqualTo: 'active')
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs.where((doc) {
                    final name = (doc['name'] ?? '').toString().toLowerCase();
                    return name.contains(searchQuery);
                  }).toList();

                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        searchQuery.isEmpty
                            ? 'Carregando salões...'
                            : 'Nenhum salão encontrado.',
                        style: TextStyle(color: AppColors.mutedForeground(context)),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (_, index) {
                      final tenant = docs[index];
                      final name = tenant['name'] ?? 'Salão';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary(context),
                            child: Text(
                              name.toString().substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(name.toString()),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => _joinByTenantId(tenant.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),
            const Text(
              'Ou inserir código do salão',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'Código',
                      hintText: 'Ex: ABC123',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: isLoadingCode ? null : _joinByCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary(context),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  child: isLoadingCode
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary),
                        )
                      : const Text('Entrar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
