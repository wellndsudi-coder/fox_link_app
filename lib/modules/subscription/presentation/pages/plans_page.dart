import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fox_link_app/core/config/plan_config.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/modules/subscription/domain/usecases/update_tenant_plan_usecase.dart';
import 'package:fox_link_app/modules/tenant/infra/datasources/tenant_remote_datasource.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  final _session = getIt<TenantSession>();
  final _updatePlan = getIt<UpdateTenantPlanUseCase>();
  final _tenantRemote = getIt<TenantRemoteDataSource>();

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

  Future<void> _showTrialDialog() async {
    final tenantId = _session.tenantId;
    if (tenantId == null) return;

    String message;
    try {
      final snapshot = await _tenantRemote.getTenant(tenantId);
      final data = snapshot.data();
      final expireDate = data?['planExpireDate'] ?? data?['expiresAt'];
      if (expireDate == null) {
        message = '30 dias grátis';
      } else {
        final DateTime date = expireDate is Timestamp
            ? expireDate.toDate()
            : (expireDate as DateTime);
        final diasRestantes = date.difference(DateTime.now()).inDays;
        message = diasRestantes <= 0
            ? 'Seu período de teste expirou'
            : 'Faltam $diasRestantes dias do seu período de teste';
      }
    } catch (_) {
      message = '30 dias grátis';
    }
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trial'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showPaidPlanDialog(String plan) {
    final priceValue = PlanConfig.price(plan);
    final priceStr = priceValue != null
        ? 'R\$ ${priceValue.toStringAsFixed(2).replaceAll('.', ',')}/mês'
        : '—';
    final title = _planLabels[plan] ?? plan;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Valor: $priceStr'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _selectPlan(plan);
            },
            child: const Text('Contratar'),
          ),
        ],
      ),
    );
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
          onTap: _showTrialDialog,
        ),
        const SizedBox(height: 12),
        _PlanCard(
          title: _planLabels[PlanConfig.basic]!,
          professionals: PlanConfig.maxProfessionals(PlanConfig.basic),
          services: PlanConfig.maxServices(PlanConfig.basic),
          onTap: () => _showPaidPlanDialog(PlanConfig.basic),
        ),
        const SizedBox(height: 12),
        _PlanCard(
          title: _planLabels[PlanConfig.professional]!,
          professionals: PlanConfig.maxProfessionals(PlanConfig.professional),
          services: PlanConfig.maxServices(PlanConfig.professional),
          onTap: () => _showPaidPlanDialog(PlanConfig.professional),
        ),
        const SizedBox(height: 12),
        _PlanCard(
          title: _planLabels[PlanConfig.enterprise]!,
          professionals: PlanConfig.maxProfessionals(PlanConfig.enterprise),
          services: PlanConfig.maxServices(PlanConfig.enterprise),
          onTap: () => _showPaidPlanDialog(PlanConfig.enterprise),
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
