import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/professionals/infra/datasources/professional_remote_datasource.dart';
import 'package:fox_link_app/modules/services/domain/entities/service.dart';
import 'package:fox_link_app/modules/services/domain/usecases/get_services.dart';

class ProfessionalServicesPage extends StatefulWidget {
  const ProfessionalServicesPage({super.key});

  @override
  State<ProfessionalServicesPage> createState() =>
      _ProfessionalServicesPageState();
}

class _ProfessionalServicesPageState extends State<ProfessionalServicesPage> {
  final _session = GetIt.I<TenantSession>();
  final _professionalRepo = GetIt.I<ProfessionalRemoteDataSource>();
  final _getServices = GetIt.I<GetServices>();

  List<Service> _services = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      var professionalId = _session.professionalId;
      if (professionalId == null && _session.uid != null) {
        final prof = await _professionalRepo.getProfessionalByUid(_session.uid!);
        if (prof != null && prof['id'] != null) {
          professionalId = prof['id'] as String;
          _session.setProfessionalId(professionalId);
        }
      }

      final tenantId = _session.tenantId;
      if (tenantId == null) {
        if (mounted) setState(() {
          _loading = false;
          _error = 'Sessão não inicializada.';
        });
        return;
      }

      final allServices = await _getServices(tenantId);
      final baseServices = allServices.where((s) => s.isBase && s.isActive).toList();

      List<Service> myServices;
      if (professionalId == null) {
        myServices = baseServices;
      } else {
        final pros = await _professionalRepo.getProfessionals();
        final p = pros.where((x) => (x['id'] as String?) == professionalId).firstOrNull;
        if (p == null) {
          myServices = baseServices;
        } else {
          final serviceIdsRaw = p['serviceIds'];
          final serviceIds = (serviceIdsRaw as List?)?.map((e) => e.toString()).toList() ?? <String>[];
          if (serviceIds.isEmpty) {
            myServices = baseServices;
          } else {
            final ids = serviceIds.toSet();
            myServices = baseServices.where((s) => ids.contains(s.id)).toList();
          }
        }
      }

      if (mounted) {
        setState(() {
          _services = myServices;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error(context)),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.mutedForeground(context)),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_services.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.design_services_outlined,
                size: 64,
                color: AppColors.mutedForeground(context),
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum serviço vinculado',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Peça ao administrador do salão para vincular os serviços que você oferece.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedForeground(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _services.length,
        itemBuilder: (_, index) {
          final s = _services[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border(context)),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
                child: Row(
                  children: [
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
                            s.name.value,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${s.baseDuration.minutes} min • '
                                'R\$ ${s.basePrice.value.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedForeground(context),
                            ),
                          ),
                        ],
                      ),
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
          );
        },
      ),
    );
  }
}
