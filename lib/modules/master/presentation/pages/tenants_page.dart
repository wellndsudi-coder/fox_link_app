import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import '../../domain/entities/tenant_entity.dart';
import '../controllers/master_controller.dart';

class TenantsPage extends StatefulWidget {
  final MasterController controller;

  const TenantsPage({super.key, required this.controller});

  @override
  State<TenantsPage> createState() => _TenantsPageState();
}

class _TenantsPageState extends State<TenantsPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadTenants();
  }

  Future<void> _showEditPlan(TenantEntity tenant) async {
    await widget.controller.loadPlans();
    if (!mounted) return;

    final plans = widget.controller.plans;
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar plano - ${tenant.name}'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: plans.length,
            itemBuilder: (_, i) {
              final p = plans[i];
              return ListTile(
                title: Text(p.name),
                subtitle: Text('R\$ ${p.price.toStringAsFixed(2)}/mês'),
                onTap: () => Navigator.pop(ctx, p.id),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
    if (selected != null && mounted) {
      await widget.controller.updateTenantPlanById(tenant.id, selected);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Plano atualizado para $selected')),
        );
      }
    }
  }

  Future<void> _showActions(TenantEntity tenant) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar plano'),
              onTap: () => Navigator.pop(ctx, 'plan'),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Ativar'),
              onTap: () => Navigator.pop(ctx, 'activate'),
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Bloquear'),
              onTap: () => Navigator.pop(ctx, 'block'),
            ),
            ListTile(
              leading: const Icon(Icons.add_alarm),
              title: const Text('Estender trial'),
              onTap: () => Navigator.pop(ctx, 'extend'),
            ),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Entrar no tenant'),
              onTap: () => Navigator.pop(ctx, 'enter'),
            ),
          ],
        ),
      ),
    );

    if (action == null || !mounted) return;

    switch (action) {
      case 'plan':
        await _showEditPlan(tenant);
        break;
      case 'activate':
        await widget.controller.updateStatus(tenant.id, 'active');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tenant ativado')),
          );
        }
        break;
      case 'block':
        await widget.controller.blockTenant(tenant.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tenant bloqueado')),
          );
        }
        break;
      case 'extend':
        if (!mounted) return;
        final days = await showDialog<int>(
          context: context,
          builder: (ctx) => _ExtendTrialDialog(),
        );
        if (days != null && mounted) {
          await widget.controller.extendTrial(tenant.id, days);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Trial estendido em $days dias')),
            );
          }
        }
        break;
      case 'enter':
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (widget.controller.loading && widget.controller.tenants.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final tenants = widget.controller.tenants;

        return RefreshIndicator(
          onRefresh: () => widget.controller.loadTenants(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    child: tenants.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: Text('Nenhum tenant cadastrado')),
                          )
                        : Table(
                            columnWidths: const {
                              0: FlexColumnWidth(2),
                              1: FlexColumnWidth(1),
                              2: FlexColumnWidth(1),
                              3: FlexColumnWidth(1),
                              4: FlexColumnWidth(1),
                              5: FlexColumnWidth(1.5),
                              6: FixedColumnWidth(56),
                            },
                            children: [
                              TableRow(
                                decoration: BoxDecoration(
                                  color: AppColors.fillColor(context),
                                ),
                                children: [
                                  _tableHeader('Nome'),
                                  _tableHeader('Plano'),
                                  _tableHeader('Status'),
                                  _tableHeader('Profissionais'),
                                  _tableHeader('Trial restante'),
                                  _tableHeader('Data criação'),
                                  const SizedBox(),
                                ],
                              ),
                              ...tenants.map((t) => TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(
                                          t.name,
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(_planLabel(t.plan)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: _StatusChip(status: t.status),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text('${t.professionalCount}'),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(t.trialDaysRemaining != null ? '${t.trialDaysRemaining} dias' : '-'),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(
                                          DateFormat('dd/MM/yyyy').format(t.createdAt),
                                          style: TextStyle(
                                            color: AppColors.mutedForeground(context),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.more_vert),
                                        onPressed: () => _showActions(t),
                                      ),
                                    ],
                                  )),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.mutedForeground(context),
        ),
      ),
    );
  }

  String _planLabel(String plan) {
    const labels = {
      'basic': 'Basic',
      'pro': 'Pro',
      'premium': 'Premium',
      'trial': 'Trial',
    };
    return labels[plan] ?? plan;
  }
}

class _ExtendTrialDialog extends StatefulWidget {
  @override
  State<_ExtendTrialDialog> createState() => _ExtendTrialDialogState();
}

class _ExtendTrialDialogState extends State<_ExtendTrialDialog> {
  final _controller = TextEditingController(text: '30');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Estender trial'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Dias adicionais'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(context, int.tryParse(_controller.text) ?? 30),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isActive ? 'Ativo' : 'Bloqueado',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isActive ? Colors.green.shade700 : Colors.orange.shade700,
        ),
      ),
    );
  }
}
