import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/get_clients_by_professional_usecase.dart';
import 'package:fox_link_app/modules/scheduling/presentation/widgets/agenda_create_appointment_sheet.dart';
import 'package:fox_link_app/modules/users/domain/repositories/user_repository.dart';
import 'package:fox_link_app/shared/widgets/app_button.dart';

class ProfessionalClientsPage extends StatefulWidget {
  const ProfessionalClientsPage({super.key});

  @override
  State<ProfessionalClientsPage> createState() => _ProfessionalClientsPageState();
}

class _ProfessionalClientsPageState extends State<ProfessionalClientsPage> {
  final _session = GetIt.I<TenantSession>();
  final _getClients = GetIt.I<GetClientsByProfessionalUseCase>();
  final _userRepo = GetIt.I<UserRepository>();
  final _searchController = TextEditingController();

  late Future<List<ClientDisplay>> _future;
  List<ClientDisplay> _allClients = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _load() {
    final profId = _session.professionalId;
    if (profId != null) {
      _future = _getClients(profId);
    } else {
      _future = Future.value(<ClientDisplay>[]);
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts.first.length >= 2) {
      return parts.first.substring(0, 2).toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  void _showClientDetail(ClientDisplay client) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _ClientDetailSheet(
        client: client,
        userRepo: _userRepo,
        onAgendar: () {
          Navigator.pop(ctx);
          _openCreateForClient(client);
        },
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _openCreateForClient(ClientDisplay client) {
    final profId = _session.professionalId;
    if (profId == null) return;

    final now = DateTime.now();
    var date = DateTime(now.year, now.month, now.day);
    var slot = DateTime(now.year, now.month, now.day, 9, 0);
    if (slot.isBefore(now)) {
      date = date.add(const Duration(days: 1));
      slot = DateTime(date.year, date.month, date.day, 9, 0);
    }

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => AgendaCreateAppointmentSheet(
        date: date,
        slot: slot,
        professionalId: profId,
        initialClientId: client.id,
        initialClientName: client.name,
        onSuccess: () => setState(() {}),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _load();
        setState(() {});
      },
      child: FutureBuilder<List<ClientDisplay>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final clients = snapshot.data ?? [];
          if (_allClients.isEmpty && clients.isNotEmpty) {
            _allClients = clients;
          }
          final filtered = _searchQuery.isEmpty
              ? clients
              : clients.where((c) =>
                  c.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

          if (clients.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: AppColors.mutedForeground(context),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Meus clientes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(context),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Clientes aparecerão aqui após o primeiro agendamento.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.mutedForeground(context),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar cliente pelo nome...',
                    prefixIcon: Icon(Icons.search, size: 20, color: AppColors.mutedForeground(context)),
                    filled: true,
                    fillColor: AppColors.fillColor(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: filtered.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          '${filtered.length} cliente${filtered.length == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppColors.mutedForeground(context),
                              ),
                        ),
                      );
                    }

                    final client = filtered[index - 1];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: AppColors.card(context),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                        child: InkWell(
                          onTap: () => _showClientDetail(client),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.accent(context),
                            child: Text(
                              _initials(client.name),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accentForeground(context),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  client.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary(context),
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Toque para ver detalhes',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.mutedForeground(context),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: AppColors.mutedForeground(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
        },
      ),
    );
  }
}

class _ClientDetailSheet extends StatefulWidget {
  final ClientDisplay client;
  final UserRepository userRepo;
  final VoidCallback onAgendar;

  const _ClientDetailSheet({
    required this.client,
    required this.userRepo,
    required this.onAgendar,
  });

  @override
  State<_ClientDetailSheet> createState() => _ClientDetailSheetState();
}

class _ClientDetailSheetState extends State<_ClientDetailSheet> {
  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await widget.userRepo.getUser(widget.client.id);
      if (mounted) {
        setState(() {
          _userData = user;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _userData = {};
          _loading = false;
        });
      }
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts.first.length >= 2) {
      return parts.first.substring(0, 2).toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _userData?['name'] ?? _userData?['displayName'] ?? _userData?['email'] ?? widget.client.name;
    final email = _userData?['email'] as String?;
    final phone = _userData?['phone'] as String?;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.accent(context),
                  child: Text(
                    _initials(name),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentForeground(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                name,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                ),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                if (email != null && email.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _InfoRow(icon: Icons.email_outlined, label: 'E-mail', value: email),
                ],
                if (phone != null && phone.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _InfoRow(icon: Icons.phone_outlined, label: 'Telefone', value: phone),
                ],
                if ((email == null || email.isEmpty) && (phone == null || phone.isEmpty))
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'Sem informações adicionais',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedForeground(context),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 32),
              AppButton(
                text: 'Agendar horário',
                onPressed: widget.onAgendar,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.mutedForeground(context)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.mutedForeground(context),
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary(context),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
