import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/auth/auth_state.dart';
import 'package:fox_link_app/core/auth/token_manager.dart';
import 'package:fox_link_app/modules/tenant/infra/datasources/tenant_remote_datasource.dart';
import 'package:fox_link_app/modules/users/infra/datasources/user_remote_datasource.dart';
import 'package:fox_link_app/shared/widgets/app_card.dart';
import 'package:fox_link_app/shared/widgets/app_section_title.dart';

class SelectTenantPage extends StatefulWidget {
  final String uid;
  final String email;

  const SelectTenantPage({
    super.key,
    required this.uid,
    required this.email,
  });

  @override
  State<SelectTenantPage> createState() => _SelectTenantPageState();
}

class _SelectTenantPageState extends State<SelectTenantPage> {

  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Escolher Salão")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const AppSectionTitle(
              title: "Escolha um salão",
              subtitle:
              "Selecione onde deseja realizar seus agendamentos.",
            ),

            const SizedBox(height: 24),

            /// 🔎 Campo de busca
            TextField(
              decoration: const InputDecoration(
                labelText: "Buscar salão",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),

            const SizedBox(height: 24),

            Expanded(
              child: FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('tenants')
                    .where('status', isEqualTo: 'active')
                    .get(const GetOptions(source: Source.server)),
                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs
                      .where((doc) {
                    final name =
                    (doc['name'] ?? '').toString().toLowerCase();
                    return name.contains(searchQuery);
                  })
                      .toList();

                  /// 🌿 Empty State Premium
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.store_mall_directory_outlined,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Nenhum salão encontrado",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Tente buscar por outro nome.",
                            style: TextStyle(
                              color: AppColors.mutedForeground(context),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (_, index) {

                      final tenant = docs[index];
                      final name = tenant['name'];

                      return Padding(
                        padding:
                        const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          onTap: () async {
                            await _createClient(
                              context,
                              tenant.id,
                            );
                          },
                          child: Row(
                            children: [

                              /// 🟣 Avatar com inicial
                              CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                Theme.of(context)
                                    .colorScheme
                                    .primary,
                                child: Text(
                                  name
                                      .toString()
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 16),

                              Expanded(
                                child: Text(
                                  name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                              ),

                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
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
      ),
    );
  }

  Future<void> _createClient(
      BuildContext context,
      String tenantId,
      ) async {

    final userRemote = getIt<UserRemoteDataSource>();
    final session = getIt<TenantSession>();
    final tenantRemote = getIt<TenantRemoteDataSource>();

    // Valida que o tenant existe antes de vincular o usuário
    final tenantDoc = await tenantRemote.getTenant(tenantId);
    if (!tenantDoc.exists || tenantDoc.data() == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Salão não encontrado. Tente novamente.')),
        );
      }
      return;
    }

    await userRemote.createUser(
      uid: widget.uid,
      email: widget.email,
      role: 'client',
      tenantId: tenantId,
    );

    session.setSession(
      tenantId: tenantId,
      role: 'client',
      uid: widget.uid,
      email: widget.email,
    );
    await getIt<TokenManager>().saveSessionData(
      tenantId: tenantId,
      uid: widget.uid,
      email: widget.email,
      roles: ['client'],
    );
    getIt<AuthState>().setAuthenticated();

    if (!context.mounted) return;
    context.go('/client');
  }
}