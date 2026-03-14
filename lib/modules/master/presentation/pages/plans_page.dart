import 'package:flutter/material.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import '../../domain/entities/plan_entity.dart';
import '../controllers/master_controller.dart';

class MasterPlansPage extends StatefulWidget {
  final MasterController controller;

  const MasterPlansPage({super.key, required this.controller});

  @override
  State<MasterPlansPage> createState() => _MasterPlansPageState();
}

class _MasterPlansPageState extends State<MasterPlansPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadPlans();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (widget.controller.loading && widget.controller.plans.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final plans = widget.controller.plans;

        return RefreshIndicator(
          onRefresh: () => widget.controller.loadPlans(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (plans.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'Nenhum plano cadastrado. Crie a coleção "plans" no Firestore.',
                        ),
                      ),
                    ),
                  )
                else
                  ...plans.map((p) => _PlanCard(
                        plan: p,
                        controller: widget.controller,
                      )),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlanCard extends StatelessWidget {
  final PlanEntity plan;
  final MasterController controller;

  const _PlanCard({required this.plan, required this.controller});

  void _openEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _PlanEditSheet(
        plan: plan,
        onSave: (updated) async {
          await controller.updatePlan(updated);
          if (context.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.star, color: AppColors.primary(context)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'R\$ ${plan.price.toStringAsFixed(2).replaceAll('.', ',')}/mês',
                        style: TextStyle(
                          color: AppColors.mutedForeground(context),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: AppColors.primary(context)),
                  onPressed: () => _openEditSheet(context),
                  tooltip: 'Editar plano',
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _BenefitRow(
              icon: Icons.people,
              label: 'Profissionais',
              value: '${plan.maxProfessionals}',
            ),
            const SizedBox(height: 8),
            _BenefitRow(
              icon: Icons.design_services,
              label: 'Serviços',
              value: '${plan.maxServices}',
            ),
            const SizedBox(height: 8),
            _BenefitRow(
              icon: Icons.add_circle_outline,
              label: 'Serviços adicionais',
              value: '${plan.maxAddonServices}',
            ),
            const SizedBox(height: 8),
            _BenefitRow(
              icon: Icons.person,
              label: 'Usuários',
              value: '${plan.maxUsers}',
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _BenefitRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary(context)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: AppColors.mutedForeground(context)),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
        ),
      ],
    );
  }
}

class _PlanEditSheet extends StatefulWidget {
  final PlanEntity plan;
  final Future<void> Function(PlanEntity) onSave;

  const _PlanEditSheet({required this.plan, required this.onSave});

  @override
  State<_PlanEditSheet> createState() => _PlanEditSheetState();
}

class _PlanEditSheetState extends State<_PlanEditSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _maxProfessionalsController;
  late final TextEditingController _maxServicesController;
  late final TextEditingController _maxAddonServicesController;
  late final TextEditingController _maxUsersController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plan.name);
    _priceController = TextEditingController(
      text: widget.plan.price.toStringAsFixed(2).replaceAll('.', ','),
    );
    _maxProfessionalsController =
        TextEditingController(text: '${widget.plan.maxProfessionals}');
    _maxServicesController =
        TextEditingController(text: '${widget.plan.maxServices}');
    _maxAddonServicesController =
        TextEditingController(text: '${widget.plan.maxAddonServices}');
    _maxUsersController =
        TextEditingController(text: '${widget.plan.maxUsers}');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _maxProfessionalsController.dispose();
    _maxServicesController.dispose();
    _maxAddonServicesController.dispose();
    _maxUsersController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome é obrigatório')),
      );
      return;
    }
    final priceStr =
        _priceController.text.trim().replaceAll(',', '.');
    final price = double.tryParse(priceStr) ?? 0;
    final maxProfessionals =
        int.tryParse(_maxProfessionalsController.text.trim()) ?? 1;
    final maxServices =
        int.tryParse(_maxServicesController.text.trim()) ?? 1;
    final maxAddonServices =
        int.tryParse(_maxAddonServicesController.text.trim()) ?? 0;
    final maxUsers =
        int.tryParse(_maxUsersController.text.trim()) ?? 1;

    if (price < 0 ||
        maxProfessionals < 1 ||
        maxServices < 1 ||
        maxAddonServices < 0 ||
        maxUsers < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Valores inválidos. Preço deve ser >= 0 e quantidades >= 1.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.onSave(PlanEntity(
        id: widget.plan.id,
        name: name,
        price: price,
        maxProfessionals: maxProfessionals,
        maxServices: maxServices,
        maxAddonServices: maxAddonServices,
        maxUsers: maxUsers,
        features: widget.plan.features,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plano atualizado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.mutedForeground(context).withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Editar plano',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do plano',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_outline),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Preço mensal (R\$)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _maxProfessionalsController,
                decoration: const InputDecoration(
                  labelText: 'Quantidade de profissionais',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _maxServicesController,
                decoration: const InputDecoration(
                  labelText: 'Quantidade de serviços',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.design_services),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _maxAddonServicesController,
                decoration: const InputDecoration(
                  labelText: 'Quantidade de serviços adicionais',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.add_circle_outline),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _maxUsersController,
                decoration: const InputDecoration(
                  labelText: 'Quantidade de usuários',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saving ? null : _handleSave,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
