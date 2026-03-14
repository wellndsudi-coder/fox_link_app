import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fox_link_app/core/config/plan_config.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/modules/tenant/infra/datasources/tenant_remote_datasource.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  final _session = getIt<TenantSession>();
  final _tenantRemote = getIt<TenantRemoteDataSource>();

  bool _isLoading = true;
  String? _plan;
  DateTime? _planExpireDate;

  static const _planLabels = {
    PlanConfig.trial: 'Trial',
    PlanConfig.basic: 'Básico',
    PlanConfig.professional: 'Profissional',
    PlanConfig.enterprise: 'Empresarial',
    PlanConfig.plus: 'Profissional',
    PlanConfig.pro: 'Empresarial',
    PlanConfig.unlimited: 'Ilimitado',
  };

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    final tenantId = _session.tenantId;
    if (tenantId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await _tenantRemote.getTenant(tenantId);
      final data = snapshot.data();
      final plan = data?['plan'] as String? ?? PlanConfig.trial;
      final expireDate = data?['planExpireDate'] ?? data?['expiresAt'];

      DateTime? planExpire;
      if (expireDate != null) {
        planExpire = expireDate is Timestamp ? expireDate.toDate() : expireDate as DateTime;
      }

      if (mounted) {
        setState(() {
          _plan = plan;
          _planExpireDate = planExpire;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _plan = PlanConfig.trial;
          _planExpireDate = null;
          _isLoading = false;
        });
      }
    }
  }

  String _getTimeRemaining() {
    if (_planExpireDate == null) {
      return 'Plano ativo';
    }
    final now = DateTime.now();
    if (_planExpireDate!.isBefore(now)) {
      return 'Período expirado';
    }
    final days = _planExpireDate!.difference(now).inDays;
    if (days == 0) {
      final hours = _planExpireDate!.difference(now).inHours;
      return 'Menos de ${hours + 1} horas restantes';
    }
    return '$days ${days == 1 ? 'dia' : 'dias'} restantes';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final plan = _plan ?? PlanConfig.trial;
    final planLabel = _planLabels[plan] ?? plan;
    final maxProfessionals = PlanConfig.maxProfessionals(plan);
    final maxServices = PlanConfig.maxServices(plan);
    final price = PlanConfig.price(plan);
    final timeRemaining = _getTimeRemaining();
    final isExpired = _planExpireDate != null && _planExpireDate!.isBefore(DateTime.now());

    return RefreshIndicator(
      onRefresh: _loadPlan,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary(context).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.star_rounded,
                            size: 32,
                            color: AppColors.primary(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Seu plano',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.mutedForeground(context),
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                planLabel,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isExpired
                            ? Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3)
                            : AppColors.fillColor(context),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tempo restante',
                            style: TextStyle(
                              color: AppColors.mutedForeground(context),
                            ),
                          ),
                          Text(
                            timeRemaining,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isExpired
                                  ? Theme.of(context).colorScheme.error
                                  : AppColors.textPrimary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Benefícios do plano',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.mutedForeground(context),
                          ),
                    ),
                    const SizedBox(height: 12),
                    _BenefitRow(
                      icon: Icons.people_outline,
                      label: 'Profissionais',
                      value: maxProfessionals >= 999999 ? 'Ilimitados' : '$maxProfessionals',
                    ),
                    const SizedBox(height: 8),
                    _BenefitRow(
                      icon: Icons.design_services,
                      label: 'Serviços',
                      value: maxServices >= 999999 ? 'Ilimitados' : '$maxServices',
                    ),
                    if (price != null) ...[
                      const SizedBox(height: 8),
                      _BenefitRow(
                        icon: Icons.payments_outlined,
                        label: 'Valor',
                        value: 'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}/mês',
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
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
          value.trim(),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
        ),
      ],
    );
  }
}
