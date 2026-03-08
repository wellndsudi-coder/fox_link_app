import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/core/config/plan_config.dart';
import 'package:fox_link_app/modules/professionals/infra/datasources/professional_remote_datasource.dart';
import 'package:fox_link_app/modules/services/domain/entities/service.dart';
import 'package:fox_link_app/modules/services/domain/usecases/get_services.dart';

class ProfessionalsPage extends StatefulWidget {
  const ProfessionalsPage({super.key});

  @override
  State<ProfessionalsPage> createState() => _ProfessionalsPageState();
}

class _ProfessionalsPageState extends State<ProfessionalsPage> {
  final _professionalRemote = getIt<ProfessionalRemoteDataSource>();
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  int _currentCount = 0;
  int _maxAllowed = 0;
  String _currentPlan = '';

  @override
  void initState() {
    super.initState();
    _loadLimits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadLimits() async {
    _currentPlan = await _professionalRemote.getCurrentPlan();
    _currentCount = await _professionalRemote.getCurrentCount();
    _maxAllowed = PlanConfig.maxProfessionals(_currentPlan);
    setState(() {});
  }

  Future<void> _createProfessional() async {
    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      if (name.isEmpty || email.isEmpty) {
        throw Exception('Nome e email são obrigatórios.');
      }
      await _professionalRemote.createProfessional(name: name, email: email);
      _nameController.clear();
      _emailController.clear();
      await _loadLimits();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Convite enviado com sucesso')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _delete(String id) async {
    await _professionalRemote.deleteProfessional(id);
    await _loadLimits();
  }

  Future<void> _openEditServices(
      String professionalId, String name, List<String> serviceIds) async {
    final tenantId = getIt<TenantSession>().tenantId;
    if (tenantId == null) return;
    final services = await getIt<GetServices>()(tenantId);
    final baseServices = services.where((s) => s.isBase).toList();
    if (!mounted) return;
    final updated = await showDialog<List<String>>(
      context: context,
      builder: (_) => _EditProfessionalServicesDialog(
        professionalName: name,
        baseServices: baseServices,
        selectedIds: List.from(serviceIds),
      ),
    );
    if (updated != null && mounted) {
      await _professionalRemote.updateProfessionalServiceIds(
        professionalId: professionalId,
        serviceIds: updated,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Serviços atualizados')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar profissional...',
              prefixIcon: Icon(
                Icons.search,
                size: 18,
                color: AppColors.mutedForeground(context),
              ),
              filled: true,
              fillColor: AppColors.fillColor(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Limits
          Text(
            'Plano: $_currentPlan | $_currentCount / $_maxAllowed usados',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.mutedForeground(context),
            ),
          ),

          const SizedBox(height: 16),

          // Add form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Nome do profissional',
                    filled: true,
                    fillColor: AppColors.fillColor(context),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadius),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email do profissional',
                    filled: true,
                    fillColor: AppColors.fillColor(context),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadius),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _createProfessional,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary(context),
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadius),
                      ),
                    ),
                    child: const Text('Enviar convite'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // List
          StreamBuilder<QuerySnapshot>(
            stream: _professionalRemote.streamProfessionals(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Nenhum profissional cadastrado',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.mutedForeground(context),
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>?;
                  final name = data?['name'] as String? ?? '';
                  final email = data?['email'] as String? ?? '';
                  final initials = name.length >= 2
                      ? name.substring(0, 2).toUpperCase()
                      : name.toUpperCase();
                  final serviceIdsRaw = data != null && data.containsKey('serviceIds')
                      ? data['serviceIds']
                      : null;
                  final serviceIds = (serviceIdsRaw as List?)
                      ?.map((e) => e.toString())
                      .toList() ?? <String>[];
                  return _ProfessionalTile(
                    professionalId: doc.id,
                    name: name,
                    email: email,
                    initials: initials,
                    serviceIds: serviceIds,
                    onEditServices: () => _openEditServices(doc.id, name, serviceIds),
                    onDelete: () => _delete(doc.id),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProfessionalTile extends StatelessWidget {
  final String professionalId;
  final String name;
  final String email;
  final String initials;
  final List<String> serviceIds;
  final VoidCallback onEditServices;
  final VoidCallback onDelete;

  const _ProfessionalTile({
    required this.professionalId,
    required this.name,
    required this.email,
    required this.initials,
    this.serviceIds = const [],
    required this.onEditServices,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary(context),
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success(context).withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusSm),
                      ),
                      child: Text(
                        'Ativo',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.success(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground(context),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.design_services,
              size: 20,
              color: AppColors.mutedForeground(context),
            ),
            tooltip: 'Serviços oferecidos',
            onPressed: onEditServices,
          ),
          IconButton(
            icon: Icon(
              Icons.schedule,
              size: 20,
              color: AppColors.mutedForeground(context),
            ),
            tooltip: 'Editar horários',
            onPressed: () => context.push(
                '/admin/professional-availability/$professionalId?name=${Uri.encodeComponent(name)}'),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              size: 20,
              color: AppColors.mutedForeground(context),
            ),
            onPressed: onDelete,
          ),
          Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.mutedForeground(context),
          ),
        ],
      ),
    );
  }
}

class _EditProfessionalServicesDialog extends StatefulWidget {
  final String professionalName;
  final List<Service> baseServices;
  final List<String> selectedIds;

  const _EditProfessionalServicesDialog({
    required this.professionalName,
    required this.baseServices,
    required this.selectedIds,
  });

  @override
  State<_EditProfessionalServicesDialog> createState() =>
      _EditProfessionalServicesDialogState();
}

class _EditProfessionalServicesDialogState
    extends State<_EditProfessionalServicesDialog> {
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedIds);
  }

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Serviços: ${widget.professionalName}'),
      content: SizedBox(
        width: 320,
        child: widget.baseServices.isEmpty
            ? Text(
                'Nenhum serviço base cadastrado',
                style: TextStyle(color: AppColors.mutedForeground(context)),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.baseServices.map((s) {
                    final selected = _selectedIds.contains(s.id);
                    return CheckboxListTile(
                      title: Text(s.name.value),
                      subtitle: Text(
                        '${s.baseDuration.minutes} min • R\$ ${s.basePrice.value.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground(context),
                        ),
                      ),
                      value: selected,
                      onChanged: (_) => _toggle(s.id),
                    );
                  }).toList(),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: TextStyle(color: AppColors.mutedForeground(context))),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedIds),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary(context)),
          child: Text('Salvar', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        ),
      ],
    );
  }
}
