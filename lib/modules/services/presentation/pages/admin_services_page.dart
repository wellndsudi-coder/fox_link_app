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
    final subs = list.where((s) => !s.isBase).toList();
    final result = <Service>[];
    final baseIds = {for (final b in bases) b.id};
    for (final b in bases) {
      result.add(b);
      result.addAll(subs.where((s) => s.parentId == b.id));
    }
    result.addAll(subs.where((s) =>
        s.parentId != null && !baseIds.contains(s.parentId)));
    return result;
  }

  void _openFormFromFab(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ServiceController>(),
        child: const ServiceFormDialog(service: null),
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
                          return _ServiceTile(
                            service: service,
                            categoryDisplay: _categoryDisplay(service, controller),
                            isSubService: !service.isBase,
                            onTap: () => _openForm(context, service: service),
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
            onPressed: () => _openFormFromFab(context),
            backgroundColor: AppColors.primary(context),
            child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
          ),
        ),
        ],
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
}

class _ServiceTile extends StatelessWidget {
  final Service service;
  final String categoryDisplay;
  final bool isSubService;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ServiceTile({
    required this.service,
    this.categoryDisplay = '',
    this.isSubService = false,
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
                  hintText: 'Ex: Corte, Barba, Coloração',
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
              if (_parentId == null) ...[
                const SizedBox(height: 16),
                _ExtrasSection(
                  baseServiceId: widget.service?.id,
                  baseServiceName: _name.text.trim().isEmpty ? widget.service?.name.value : _name.text.trim(),
                  onExtraCreated: () async {
                    await context.read<ServiceController>().loadServices();
                    if (context.mounted) setState(() {});
                  },
                ),
              ],
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
                  hintText: '0,00',
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
                  hintText: 'Ex: 30',
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

class _ExtrasSection extends StatefulWidget {
  final String? baseServiceId;
  final String? baseServiceName;
  final VoidCallback onExtraCreated;

  const _ExtrasSection({
    required this.baseServiceId,
    this.baseServiceName,
    required this.onExtraCreated,
  });

  @override
  State<_ExtrasSection> createState() => _ExtrasSectionState();
}

class _ExtrasSectionState extends State<_ExtrasSection> {
  List<Service> _addons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAddons();
  }

  Future<void> _loadAddons() async {
    final tenantId = getIt<TenantSession>().tenantId;
    if (tenantId == null || widget.baseServiceId == null) {
      setState(() {
        _addons = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    final list = await getIt<GetAddonsForBaseServiceUseCase>()(tenantId, widget.baseServiceId!);
    setState(() {
      _addons = list;
      _loading = false;
    });
  }

  @override
  void didUpdateWidget(covariant _ExtrasSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.baseServiceId != widget.baseServiceId) _loadAddons();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.fillColor(context),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Extras que podem ser adicionados',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          if (widget.baseServiceId == null)
            Text(
              'Salve o serviço primeiro para criar ou vincular extras.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.mutedForeground(context),
              ),
            )
          else if (_loading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else ...[
            if (_addons.isNotEmpty)
              ..._addons.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${s.name.value} • ${s.baseDuration.minutes} min • R\$ ${s.basePrice.value.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 13, color: AppColors.textPrimary(context)),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, size: 18, color: AppColors.mutedForeground(context)),
                          onPressed: () async {
                            final ctrl = context.read<ServiceController>();
                            await ctrl.delete(s);
                            widget.onExtraCreated();
                          },
                        ),
                      ],
                    ),
                  )),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Criar extra'),
                  onPressed: () async {
                    final controller = context.read<ServiceController>();
                    final created = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => _CreateExtraDialog(
                        baseServiceId: widget.baseServiceId!,
                        baseServiceName: widget.baseServiceName ?? 'Serviço',
                        controller: controller,
                      ),
                    );
                    if (created == true) {
                      await _loadAddons();
                      widget.onExtraCreated();
                    }
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.link, size: 18),
                  label: const Text('Vincular extra existente'),
                  onPressed: () async {
                    final ctrl = context.read<ServiceController>();
                    final candidates = ctrl.services
                        .where((s) =>
                            !s.isBase &&
                            s.parentId != widget.baseServiceId &&
                            s.isActive)
                        .toList();
                    if (candidates.isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Não há extras disponíveis para vincular.')),
                        );
                      }
                      return;
                    }
                    final picked = await showDialog<Service>(
                      context: context,
                      builder: (ctx) => _SelectExtraToLinkDialog(
                        addons: candidates,
                        baseServiceId: widget.baseServiceId!,
                      ),
                    );
                    if (picked != null) {
                      await ctrl.update(picked.copyWith(parentId: widget.baseServiceId));
                      await _loadAddons();
                      widget.onExtraCreated();
                    }
                  },
                ),
              ],
            ),
          ],
        ],
      ),
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
              hintText: 'Ex: Coloração, Barba',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Preço (R\$)',
              hintText: '0,00',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _durationController,
            decoration: const InputDecoration(
              labelText: 'Duração (minutos)',
              hintText: '15',
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
            await widget.controller.create(
              name: name,
              price: price,
              duration: duration,
              allowChangePrice: false,
              allowChangeDuration: false,
              parentId: widget.baseServiceId,
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
          hintText: 'Ex: Cabelo, Barba',
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