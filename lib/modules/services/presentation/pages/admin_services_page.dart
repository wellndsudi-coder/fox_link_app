import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fox_link_app/core/theme/app_theme.dart';
import '../controllers/service_controller.dart';
import '../../domain/entities/service.dart';
import '../../domain/value_objects/money.dart';
import '../../domain/value_objects/service_name.dart';
import '../../domain/value_objects/service_duration.dart';

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

  static const _chips = ['Todos', 'Cabelo', 'Barba', 'Tratamento', 'Unhas'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Service> _filtered(ServiceController controller) {
    var list = controller.services;
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where(
        (s) => s.name.value.toLowerCase().contains(q),
      ).toList();
    }
    return list;
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
      color: AppTheme.backgroundColor,
      child: Stack(
        children: [
          Padding(
      padding: const EdgeInsets.all(16),
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
                color: AppTheme.mutedForeground,
              ),
              filled: true,
              fillColor: AppTheme.secondaryColor,
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
              children: _chips.map((label) {
                final selected = _selectedChip == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedChip = label),
                    selectedColor: AppTheme.accentColor,
                    checkmarkColor: AppTheme.accentForeground,
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
                style: const TextStyle(
                  color: AppTheme.errorColor,
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
                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            'Nenhum serviço cadastrado',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.mutedForeground,
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
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
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
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ServiceTile({
    required this.service,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    borderRadius:
                        BorderRadius.circular(AppTheme.borderRadiusMd),
                  ),
                  child: Icon(
                    Icons.content_cut,
                    color: AppTheme.accentForeground,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name.value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.foregroundColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${service.baseDuration.minutes} min • '
                            'R\$ ${service.basePrice.value.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedForeground,
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
                    color: AppTheme.mutedForeground,
                  ),
                  onPressed: onDelete,
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppTheme.mutedForeground,
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

    allowPriceChange =
        widget.service?.allowProfessionalChangePrice ??
            false;

    allowDurationChange =
        widget.service?.allowProfessionalChangeDuration ??
            false;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ServiceController>();

    return AlertDialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      title: Text(
        widget.service == null ? 'Novo Serviço' : 'Editar Serviço',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppTheme.foregroundColor,
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
                  fillColor: AppTheme.secondaryColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _price,
                decoration: InputDecoration(
                  labelText: 'Preço (R\$)',
                  hintText: '0,00',
                  filled: true,
                  fillColor: AppTheme.secondaryColor,
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
                  fillColor: AppTheme.secondaryColor,
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
                  color: AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'Permitir alterar preço',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.foregroundColor,
                        ),
                      ),
                      value: allowPriceChange,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (v) => setState(() => allowPriceChange = v),
                    ),
                    SwitchListTile(
                      title: const Text(
                        'Permitir alterar duração',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.foregroundColor,
                        ),
                      ),
                      value: allowDurationChange,
                      activeColor: AppTheme.primaryColor,
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
            style: TextStyle(color: AppTheme.mutedForeground),
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
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}