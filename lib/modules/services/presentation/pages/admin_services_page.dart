import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';

import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/layout/layout_breakpoints.dart';
import '../controllers/service_controller.dart';
import '../../domain/entities/service.dart';
import '../../domain/entities/service_category.dart';
import '../../domain/value_objects/money.dart';
import '../../domain/value_objects/service_name.dart';
import '../../domain/value_objects/service_duration.dart';
import '../../domain/usecases/create_service_category_usecase.dart';
import '../../domain/usecases/delete_service_category_usecase.dart';
import '../../domain/usecases/get_addons_for_base_service_usecase.dart';

class AdminServicesPage extends StatelessWidget {
  const AdminServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ServiceController()..loadServices(),
      child: const _AdminServicesView(),
    );
  }
}

class _AdminServicesView extends StatefulWidget {
  const _AdminServicesView();

  @override
  State<_AdminServicesView> createState() => _AdminServicesViewState();
}

class _AdminServicesViewState extends State<_AdminServicesView> {
  final _searchController = TextEditingController();
  String _selectedChip = 'Todos';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _categoryDisplay(Service s, ServiceController controller) {
    if (s.category != null && s.category!.isNotEmpty) return s.category!;
    if (s.categoryId != null) {
      final c = controller.categories
          .where((cat) => cat.id == s.categoryId)
          .firstOrNull;
      if (c != null) return c.name;
    }
    return '';
  }

  List<Service> _filtered(ServiceController controller) {
    var list = controller.services;
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where(
        (s) => s.name.value.toLowerCase().contains(q) ||
            _categoryDisplay(s, controller).toLowerCase().contains(q),
      ).toList();
    }
    if (_selectedChip != 'Todos') {
      list = list.where((s) => _categoryDisplay(s, controller) == _selectedChip).toList();
    }
    return list;
  }

  List<String> _categoryChips(ServiceController controller) {
    final cats = <String>{'Todos'};
    for (final s in controller.services) {
      final name = _categoryDisplay(s, controller);
      if (name.isNotEmpty) cats.add(name);
    }
    for (final c in controller.categories) {
      cats.add(c.name);
    }
    return cats.toList()..sort((a, b) => a == 'Todos' ? -1 : a.compareTo(b));
  }

  List<Service> _groupedForDisplay(List<Service> list) {
    final bases = list.where((s) => s.isBase).toList();
    final addons = list.where((s) => s.isAddon).toList();
    final result = <Service>[];
    final baseIds = {for (final b in bases) b.id};
    for (final b in bases) {
      result.add(b);
      result.addAll(addons.where((s) =>
          s.parentId == b.id || s.linkedBaseServiceIds.contains(b.id)));
    }
    result.addAll(addons.where((s) =>
        (s.parentId == null || !baseIds.contains(s.parentId!)) &&
        s.linkedBaseServiceIds.every((id) => !baseIds.contains(id))));
    return result;
  }

  void _openCreateChoiceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'O que deseja criar?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(ctx),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.content_cut),
                title: const Text('Criar serviço'),
                subtitle: Text(
                  'Novo serviço base',
                  style: TextStyle(fontSize: 12, color: AppColors.mutedForeground(ctx)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _openForm(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Criar adicionais'),
                subtitle: Text(
                  'Adicional que pode ser vinculado a qualquer serviço',
                  style: TextStyle(fontSize: 12, color: AppColors.mutedForeground(ctx)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _openCreateAddonForm(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openForm(BuildContext context, {Service? service}) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ServiceController>(),
        child: ServiceFormDialog(service: service),
      ),
    );
  }

  void _openCreateAddonForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ServiceController>(),
        child: const CreateAddonDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ServiceController>();

    return Container(
      color: AppColors.background(context),
      child: Stack(
        children: [
          Padding(
      padding: LayoutBreakpoints.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Buscar serviço...',
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categoryChips(controller).map((label) {
                final selected = _selectedChip == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedChip = label),
                    selectedColor: AppColors.accent(context),
                    checkmarkColor: AppColors.accentForeground(context),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          if (controller.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                controller.error!,
                style: TextStyle(
                  color: AppColors.error(context),
                  fontSize: 14,
                ),
              ),
            ),
          Expanded(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Builder(
                    builder: (_) {
                      final filtered = _filtered(controller);
                      final grouped = _groupedForDisplay(filtered);
                      if (grouped.isEmpty) {
                        return Center(
                          child: Text(
                            'Nenhum serviço cadastrado',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.mutedForeground(context),
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, index) {
                          final service = filtered[index];
                          final addons = service.isBase
                              ? controller.services.where((s) =>
                                  s.isAddon &&
                                  s.isActive &&
                                  (s.parentId == service.id ||
                                      s.linkedBaseServiceIds.contains(service.id)))
                                  .toList()
                              : <Service>[];
                          return _ServiceTile(
                            service: service,
                            categoryDisplay: _categoryDisplay(service, controller),
                            isSubService: service.isAddon,
                            addons: addons,
                            onTap: () => _openDetail(context, service: service),
                            onToggle: () => controller.toggle(service),
                            onDelete: () => controller.delete(service),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => _openCreateChoiceModal(context),
            backgroundColor: AppColors.primary(context),
            child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
          ),
        ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, {required Service service}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ServiceController>(),
        child: ServiceDetailSheet(
          service: service,
          categoryDisplay: _categoryDisplay(service, context.read<ServiceController>()),
          onEdit: () {
            Navigator.pop(context);
            _openForm(context, service: service);
          },
          onExtraAdded: () async {
            await context.read<ServiceController>().loadServices();
            if (context.mounted) setState(() {});
          },
        ),
      ),
    );
  }
}

class ServiceDetailSheet extends StatefulWidget {
  final Service service;
  final String categoryDisplay;
  final VoidCallback onEdit;
  final VoidCallback onExtraAdded;

  const ServiceDetailSheet({
    super.key,
    required this.service,
    required this.categoryDisplay,
    required this.onEdit,
    required this.onExtraAdded,
  });

  @override
  State<ServiceDetailSheet> createState() => _ServiceDetailSheetState();
}

class _ServiceDetailSheetState extends State<ServiceDetailSheet> {
  List<Service> _addons = [];
  bool _loadingAddons = true;

  @override
  void initState() {
    super.initState();
    _loadAddons();
  }

  Future<void> _loadAddons() async {
    if (!widget.service.isBase) {
      setState(() => _loadingAddons = false);
      return;
    }
    final tenantId = getIt<TenantSession>().tenantId;
    if (tenantId == null) {
      setState(() => _loadingAddons = false);
      return;
    }
    setState(() => _loadingAddons = true);
    final list = await getIt<GetAddonsForBaseServiceUseCase>()(tenantId, widget.service.id);
    if (mounted) setState(() {
      _addons = list;
      _loadingAddons = false;
    });
  }

  void _showAddExtraOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Adicionar serviço extra',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(ctx),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Escolha como adicionar o extra a ${widget.service.name.value}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedForeground(ctx),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _linkExistingExtra(ctx);
                },
                icon: const Icon(Icons.link),
                label: const Text('Escolher existente'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.centerLeft,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _createNewExtra(ctx);
                },
                icon: const Icon(Icons.add),
                label: const Text('Criar novo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.centerLeft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _linkExistingExtra(BuildContext ctx) async {
    final ctrl = context.read<ServiceController>();
    final baseId = widget.service.id;
    final candidates = ctrl.services
        .where((s) =>
            s.isAddon &&
            s.isActive &&
            !s.linkedBaseServiceIds.contains(baseId) &&
            s.parentId != baseId)
        .toList();
    if (candidates.isEmpty) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Não há adicionais disponíveis para vincular. Crie um adicional primeiro em "Criar serviços" > "Criar adicionais".')),
        );
      }
      return;
    }
    final picked = await showDialog<Service>(
      context: ctx,
      builder: (c) => _SelectExtraToLinkDialog(
        addons: candidates,
        baseServiceId: widget.service.id,
      ),
    );
    if (picked != null) {
      final ids = List<String>.from(picked.linkedBaseServiceIds);
      if (!ids.contains(widget.service.id)) ids.add(widget.service.id);
      await ctrl.update(picked.copyWith(
        parentId: null,
        linkedBaseServiceIds: ids,
      ));
      await _loadAddons();
      widget.onExtraAdded();
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Extra vinculado com sucesso.')),
        );
      }
    }
  }

  Future<void> _createNewExtra(BuildContext ctx) async {
    final controller = context.read<ServiceController>();
    final created = await showDialog<bool>(
      context: ctx,
      builder: (c) => _CreateExtraDialog(
        baseServiceId: widget.service.id,
        baseServiceName: widget.service.name.value,
        controller: controller,
      ),
    );
    if (created == true) {
      await _loadAddons();
      widget.onExtraAdded();
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Extra criado com sucesso.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.accent(context),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                  ),
                  child: Icon(Icons.content_cut, color: AppColors.accentForeground(context), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name.value,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      if (widget.categoryDisplay.isNotEmpty)
                        Text(
                          widget.categoryDisplay,
                          style: TextStyle(fontSize: 13, color: AppColors.mutedForeground(context)),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '${s.baseDuration.minutes} min • R\$ ${s.basePrice.value.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 14, color: AppColors.mutedForeground(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (s.description != null && s.description!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Descrição',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s.description!,
                style: TextStyle(fontSize: 14, color: AppColors.mutedForeground(context)),
              ),
            ],
            if (s.isBase) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Serviços extras',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showAddExtraOptions,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Adicionar extra'),
                  ),
                ],
              ),
              if (_loadingAddons)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_addons.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.fillColor(context),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  ),
                  child: Text(
                    'Nenhum extra vinculado. Toque em "Adicionar extra" para escolher um existente ou criar novo.',
                    style: TextStyle(fontSize: 14, color: AppColors.mutedForeground(context)),
                  ),
                )
              else
                ..._addons.map((extra) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.fillColor(context),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              extra.name.value,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            Text(
                              '${extra.baseDuration.minutes} min • R\$ ${extra.basePrice.value.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 12, color: AppColors.mutedForeground(context)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.link_off, size: 20, color: AppColors.mutedForeground(context)),
                        tooltip: 'Desvincular deste serviço',
                        onPressed: () async {
                          final ctrl = context.read<ServiceController>();
                          await ctrl.unlinkAddonFromService(extra, widget.service.id);
                          await _loadAddons();
                          widget.onExtraAdded();
                        },
                      ),
                    ],
                  ),
                )),
            ],
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onEdit,
                    child: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary(context),
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: const Text('Fechar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final Service service;
  final String categoryDisplay;
  final bool isSubService;
  final List<Service> addons;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ServiceTile({
    required this.service,
    this.categoryDisplay = '',
    this.isSubService = false,
    this.addons = const [],
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border(context)),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
            child: Row(
              children: [
                if (isSubService) const SizedBox(width: 24),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent(context),
                    borderRadius:
                        BorderRadius.circular(AppTheme.borderRadiusMd),
                  ),
                  child: Icon(
                    Icons.content_cut,
                    color: AppColors.accentForeground(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name.value,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      if (categoryDisplay.isNotEmpty)
                        Text(
                          categoryDisplay,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.mutedForeground(context),
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        '${service.baseDuration.minutes} min • '
                            'R\$ ${service.basePrice.value.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground(context),
                        ),
                      ),
                      if (addons.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: addons.map((a) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent(context).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              a.name.value,
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.accentForeground(context),
                              ),
                            ),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                Switch(
                  value: service.isActive,
                  onChanged: (_) => onToggle(),
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
          ),
        ),
      ),
    );
  }
}

class ServiceFormDialog extends StatefulWidget {
  final Service? service;

  const ServiceFormDialog({super.key, this.service});

  @override
  State<ServiceFormDialog> createState() =>
      _ServiceFormDialogState();
}

class _ServiceFormDialogState
    extends State<ServiceFormDialog> {

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _name;
  late TextEditingController _price;
  late TextEditingController _duration;
  late TextEditingController _category;
  late TextEditingController _description;

  String? _parentId;
  String? _categoryId;
  int? _color;
  bool allowPriceChange = false;
  bool allowDurationChange = false;

  @override
  void initState() {
    super.initState();

    _name = TextEditingController(
        text: widget.service?.name.value ?? '');
    _price = TextEditingController(
        text: widget.service?.basePrice.value
            .toString() ??
            '');
    _duration = TextEditingController(
        text: widget.service?.baseDuration.minutes
            .toString() ??
            '');
    _category = TextEditingController(
        text: widget.service?.category ?? '');
    _description = TextEditingController(
        text: widget.service?.description ?? '');
    _parentId = widget.service?.parentId;
    _categoryId = widget.service?.categoryId;
    _color = widget.service?.color;

    allowPriceChange =
        widget.service?.allowProfessionalChangePrice ??
            false;

    allowDurationChange =
        widget.service?.allowProfessionalChangeDuration ??
            false;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _duration.dispose();
    _category.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ServiceController>();

    return AlertDialog(
      backgroundColor: AppColors.card(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      title: Text(
        widget.service == null ? 'Novo Serviço' : 'Editar Serviço',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary(context),
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: 'Nome do serviço',
                  hintText: 'Nome do serviço',
                  filled: true,
                  fillColor: AppColors.fillColor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _categoryId,
                      decoration: InputDecoration(
                        labelText: 'Categoria',
                        filled: true,
                        fillColor: AppColors.fillColor(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Nenhuma')),
                        ...controller.categories.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        )),
                      ],
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: 'Nova categoria',
                    onPressed: () async {
                      final catId = await showDialog<String>(
                        context: context,
                        builder: (ctx) => _AddCategoryDialog(),
                      );
                      if (catId != null && context.mounted) {
                        await controller.loadCategories();
                        setState(() => _categoryId = catId);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    tooltip: 'Gerenciar e excluir categorias',
                    onPressed: () async {
                      await showDialog(
                        context: context,
                        builder: (ctx) => _ManageCategoriesDialog(
                          categories: controller.categories,
                          onDeleted: () async {
                            await controller.loadCategories();
                            if (context.mounted) setState(() => _categoryId = null);
                          },
                        ),
                      );
                      if (context.mounted) {
                        await controller.loadCategories();
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Descrição (opcional)',
                  hintText: 'Descrição do serviço',
                  filled: true,
                  fillColor: AppColors.fillColor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _price,
                decoration: InputDecoration(
                  labelText: 'Preço (R\$)',
                  hintText: 'Valor',
                  filled: true,
                  fillColor: AppColors.fillColor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obrigatório';
                  final n = double.tryParse(v.replaceAll(',', '.'));
                  if (n == null || n < 0) return 'Preço inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _duration,
                decoration: InputDecoration(
                  labelText: 'Duração (minutos)',
                  hintText: 'Duração (min)',
                  filled: true,
                  fillColor: AppColors.fillColor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obrigatório';
                  final n = int.tryParse(v);
                  if (n == null || n < 1) return 'Duração inválida (mín. 1 min)';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.fillColor(context),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        'Permitir alterar preço',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      value: allowPriceChange,
                      activeColor: AppColors.primary(context),
                      onChanged: (v) => setState(() => allowPriceChange = v),
                    ),
                    SwitchListTile(
                      title: Text(
                        'Permitir alterar duração',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      value: allowDurationChange,
                      activeColor: AppColors.primary(context),
                      onChanged: (v) => setState(() => allowDurationChange = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: TextStyle(color: AppColors.mutedForeground(context)),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;

            if (widget.service == null) {
              await controller.create(
                name: _name.text.trim(),
                price: double.tryParse(_price.text.replaceAll(',', '.')) ?? 0,
                duration: int.tryParse(_duration.text) ?? 30,
                allowChangePrice: allowPriceChange,
                allowChangeDuration: allowDurationChange,
                parentId: _parentId,
                category: _category.text.trim().isEmpty ? null : _category.text.trim(),
                categoryId: _categoryId,
                description: _description.text.trim().isEmpty ? null : _description.text.trim(),
                color: _color,
              );
            } else {
              await controller.update(
                widget.service!.copyWith(
                  name: ServiceName(_name.text.trim()),
                  basePrice: Money(
                    double.tryParse(_price.text.replaceAll(',', '.')) ?? 0,
                  ),
                  baseDuration: ServiceDuration(
                    int.tryParse(_duration.text) ?? 30,
                  ),
                  allowProfessionalChangePrice: allowPriceChange,
                  allowProfessionalChangeDuration: allowDurationChange,
                  parentId: _parentId,
                  category: _category.text.trim().isEmpty ? null : _category.text.trim(),
                  categoryId: _categoryId,
                  description: _description.text.trim().isEmpty ? null : _description.text.trim(),
                  color: _color,
                ),
              );
            }

            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    widget.service == null
                        ? 'Serviço criado com sucesso'
                        : 'Serviço atualizado',
                  ),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary(context),
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class CreateAddonDialog extends StatefulWidget {
  const CreateAddonDialog({super.key});

  @override
  State<CreateAddonDialog> createState() => _CreateAddonDialogState();
}

class _CreateAddonDialogState extends State<CreateAddonDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController(text: '15');

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ServiceController>();
    return AlertDialog(
      title: const Text('Criar adicional'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Adicione um adicional que poderá ser vinculado a qualquer serviço, quantas vezes quiser.',
            style: TextStyle(fontSize: 13, color: AppColors.mutedForeground(context)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nome do adicional',
              hintText: 'Nome do add-on',
              filled: true,
              fillColor: AppColors.fillColor(context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.borderRadius), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            decoration: InputDecoration(
              labelText: 'Preço (R\$)',
              hintText: 'Valor',
              filled: true,
              fillColor: AppColors.fillColor(context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.borderRadius), borderSide: BorderSide.none),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _durationController,
            decoration: InputDecoration(
              labelText: 'Duração (minutos)',
              hintText: 'Duração (min)',
              filled: true,
              fillColor: AppColors.fillColor(context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.borderRadius), borderSide: BorderSide.none),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: TextStyle(color: AppColors.mutedForeground(context))),
        ),
        ElevatedButton(
          onPressed: () async {
            final name = _nameController.text.trim();
            final price = double.tryParse(_priceController.text.replaceAll(',', '.'));
            final duration = int.tryParse(_durationController.text);
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nome é obrigatório')));
              return;
            }
            if (price == null || price < 0) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preço inválido')));
              return;
            }
            if (duration == null || duration < 1) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Duração inválida (mín. 1 min)')));
              return;
            }
            await controller.createAddon(name: name, price: price, duration: duration);
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adicional criado. Vincule a qualquer serviço.')));
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary(context)),
          child: Text('Criar', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        ),
      ],
    );
  }
}

class _CreateExtraDialog extends StatefulWidget {
  final String baseServiceId;
  final String baseServiceName;
  final ServiceController controller;

  const _CreateExtraDialog({
    required this.baseServiceId,
    required this.baseServiceName,
    required this.controller,
  });

  @override
  State<_CreateExtraDialog> createState() => _CreateExtraDialogState();
}

class _CreateExtraDialogState extends State<_CreateExtraDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController(text: '15');

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Criar extra'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Extra para: ${widget.baseServiceName}',
            style: TextStyle(fontSize: 12, color: AppColors.mutedForeground(context)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome do extra',
              hintText: 'Nome do add-on',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Preço (R\$)',
              hintText: 'Valor',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _durationController,
            decoration: const InputDecoration(
              labelText: 'Duração (minutos)',
              hintText: 'Duração (min)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancelar', style: TextStyle(color: AppColors.mutedForeground(context))),
        ),
        ElevatedButton(
          onPressed: () async {
            final name = _nameController.text.trim();
            final price = double.tryParse(_priceController.text.replaceAll(',', '.'));
            final duration = int.tryParse(_durationController.text);
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nome é obrigatório')));
              return;
            }
            if (price == null || price < 0) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preço inválido')));
              return;
            }
            if (duration == null || duration < 1) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Duração inválida (mín. 1 min)')));
              return;
            }
            await widget.controller.createAddon(
              name: name,
              price: price,
              duration: duration,
              linkToBaseServiceIds: [widget.baseServiceId],
            );
            if (context.mounted) Navigator.pop(context, true);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary(context)),
          child: Text('Criar', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        ),
      ],
    );
  }
}

class _SelectExtraToLinkDialog extends StatelessWidget {
  final List<Service> addons;
  final String baseServiceId;

  const _SelectExtraToLinkDialog({
    required this.addons,
    required this.baseServiceId,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Vincular extra existente'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: addons.length,
          itemBuilder: (_, i) {
            final s = addons[i];
            return ListTile(
              title: Text(s.name.value),
              subtitle: Text(
                '${s.baseDuration.minutes} min • R\$ ${s.basePrice.value.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 12, color: AppColors.mutedForeground(context)),
              ),
              onTap: () => Navigator.pop(context, s),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

class _ManageCategoriesDialog extends StatelessWidget {
  final List<ServiceCategory> categories;
  final VoidCallback? onDeleted;

  const _ManageCategoriesDialog({
    required this.categories,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final session = getIt<TenantSession>();
    final tenantId = session.tenantId;

    return AlertDialog(
      title: const Text('Gerenciar categorias'),
      content: SizedBox(
        width: double.maxFinite,
        child: categories.isEmpty
            ? Text(
                'Nenhuma categoria cadastrada.',
                style: TextStyle(color: AppColors.mutedForeground(context)),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: categories.length,
                itemBuilder: (_, i) {
                  final c = categories[i];
                  return ListTile(
                    title: Text(c.name),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: AppColors.error(context)),
                      tooltip: 'Excluir categoria',
                      onPressed: tenantId == null
                          ? null
                          : () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Excluir categoria?'),
                                  content: Text(
                                    'A categoria "${c.name}" será excluída. Serviços vinculados não serão removidos.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text('Excluir', style: TextStyle(color: AppColors.error(ctx))),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                await getIt<DeleteServiceCategoryUseCase>()(c.id, tenantId);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                  onDeleted?.call();
                                }
                              }
                            },
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}

class _AddCategoryDialog extends StatefulWidget {
  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova categoria'),
      content: TextField(
        controller: _nameController,
        decoration: InputDecoration(
          labelText: 'Nome',
          hintText: 'Nome da categoria',
          filled: true,
          fillColor: AppColors.fillColor(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            borderSide: BorderSide.none,
          ),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: TextStyle(color: AppColors.mutedForeground(context))),
        ),
        ElevatedButton(
          onPressed: () async {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            try {
              final session = getIt<TenantSession>();
              final tenantId = session.tenantId;
              if (tenantId == null) return;
              final cat = ServiceCategory(
                id: const Uuid().v4(),
                tenantId: tenantId,
                name: name,
              );
              await getIt<CreateServiceCategoryUseCase>()(cat);
              if (context.mounted) Navigator.pop(context, cat.id);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary(context)),
          child: Text('Criar', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        ),
      ],
    );
  }
}