import '../entities/financial_stats_entity.dart';
import '../entities/platform_log_entity.dart';
import '../entities/platform_settings_entity.dart';
import '../entities/platform_stats_entity.dart';
import '../entities/plan_entity.dart';
import '../entities/tenant_entity.dart';
import '../entities/user_entity.dart';

/// Repositório do módulo Master para gerenciamento do SaaS.
abstract class MasterRepository {
  Future<List<TenantEntity>> getTenants();
  Future<void> updateTenantPlan({required String tenantId, required String plan});
  Future<void> updateTenantStatus({required String tenantId, required String status});
  Future<void> blockTenant({required String tenantId});
  Future<void> extendTrial({required String tenantId, required int days});
  Future<List<PlanEntity>> getPlans();
  Future<void> updatePlan(PlanEntity plan);
  Future<MasterMetrics> getMetrics();
  Future<List<MasterUserEntity>> getUsers();
  Future<PlatformStatsEntity> getPlatformStats();
  Future<FinancialStatsEntity> getFinancialStats();
  Future<List<PlatformLogEntity>> getLogs({int limit = 100});
  Future<PlatformSettingsEntity> getSettings();
  Future<void> saveSettings(PlatformSettingsEntity settings);
}

/// Métricas agregadas da plataforma.
class MasterMetrics {
  final int totalTenants;
  final int activeTenants;
  final int totalUsers;
  final int appointmentsToday;
  final double monthlyRevenue;
  final int trialActive;

  const MasterMetrics({
    required this.totalTenants,
    required this.activeTenants,
    required this.totalUsers,
    required this.appointmentsToday,
    this.monthlyRevenue = 0,
    this.trialActive = 0,
  });
}
