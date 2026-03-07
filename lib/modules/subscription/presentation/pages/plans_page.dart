import 'package:flutter/material.dart';
import 'package:fox_link_app/core/config/plan_config.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/modules/subscription/domain/usecases/update_tenant_plan_usecase.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  final _session = getIt<TenantSession>();
  final _updatePlan = getIt<UpdateTenantPlanUseCase>();

  bool _isLoading = false;

  static const _planLabels = {
    PlanConfig.trial: 'Trial',
    PlanConfig.basic: 'Básico',
    PlanConfig.professional: 'Profissional',
    PlanConfig.enterprise: 'Empresarial',
  };

  Future<void> _selectPlan(String plan) async {
    final tenantId = _session.tenantId;
    if (tenantId == null) return;

    setState(() => _isLoading = true);

    try {
      await _updatePlan(tenantId: tenantId, plan: plan);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plano atualizado para ${_planLabels[plan]}')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PlanCard(
          title: _planLabels[PlanConfig.trial]!,
          professionals: PlanConfig.maxProfessionals(PlanConfig.trial),
          services: PlanConfig.maxServices(PlanConfig.trial),
          subtitle: '30 dias grátis',
          onTap: () => _selectPlan(PlanConfig.trial),
        ),
        const SizedBox(height: 12),
        _PlanCard(
          title: _planLabels[PlanConfig.basic]!,
          professionals: PlanConfig.maxProfessionals(PlanConfig.basic),
          services: PlanConfig.maxServices(PlanConfig.basic),
          onTap: () => _selectPlan(PlanConfig.basic),
        ),
        const SizedBox(height: 12),
        _PlanCard(
          title: _planLabels[PlanConfig.professional]!,
          professionals: PlanConfig.maxProfessionals(PlanConfig.professional),
          services: PlanConfig.maxServices(PlanConfig.professional),
          onTap: () => _selectPlan(PlanConfig.professional),
        ),
        const SizedBox(height: 12),
        _PlanCard(
          title: _planLabels[PlanConfig.enterprise]!,
          professionals: PlanConfig.maxProfessionals(PlanConfig.enterprise),
          services: PlanConfig.maxServices(PlanConfig.enterprise),
          onTap: () => _selectPlan(PlanConfig.enterprise),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final int professionals;
  final int services;
  final String? subtitle;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.professionals,
    required this.services,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$professionals profissionais, $services serviços${subtitle != null ? ' • $subtitle' : ''}',
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
