import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fox_link_app/core/config/plan_config.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/modules/tenant/infra/datasources/tenant_remote_datasource.dart';
import 'package:fox_link_app/modules/subscription/presentation/pages/plans_page.dart';

class TrialBanner extends StatelessWidget {
  const TrialBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final tenantId = getIt<TenantSession>().tenantId;
    if (tenantId == null) return const SizedBox.shrink();

    return FutureBuilder<Map<String, dynamic>?>(
      future: getIt<TenantRemoteDataSource>()
          .getTenant(tenantId)
          .then((s) => s.data()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final data = snapshot.data!;
        final plan = data['plan'] as String? ?? PlanConfig.trial;
        if (plan != PlanConfig.trial) return const SizedBox.shrink();

        final expire = data['planExpireDate'] ?? data['expiresAt'];
        if (expire == null) return const SizedBox.shrink();

        final DateTime expiryDate;
        if (expire is Timestamp) {
          expiryDate = expire.toDate();
        } else if (expire is DateTime) {
          expiryDate = expire;
        } else {
          return const SizedBox.shrink();
        }

        final daysLeft = expiryDate.difference(DateTime.now()).inDays;
        if (daysLeft > 7) return const SizedBox.shrink();

    return Material(
      color: Colors.orange.shade100,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PlansPage(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  daysLeft <= 0
                      ? 'Seu período de teste expirou. Escolha um plano.'
                      : 'Seu período de teste termina em $daysLeft dias.',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.orange.shade800),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}
