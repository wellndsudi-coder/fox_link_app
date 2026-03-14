import '../../domain/entities/financial_stats_entity.dart';
import '../../domain/entities/platform_log_entity.dart';
import '../../domain/entities/platform_settings_entity.dart';
import '../../domain/entities/platform_stats_entity.dart';
import '../../domain/entities/plan_entity.dart';
import '../../domain/entities/tenant_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/master_repository.dart';
import '../datasources/master_remote_datasource.dart';

class MasterRepositoryImpl implements MasterRepository {
  final MasterRemoteDataSource dataSource;

  MasterRepositoryImpl(this.dataSource);

  @override
  Future<List<TenantEntity>> getTenants() async {
    try {
      return await dataSource.getTenants();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> updateTenantPlan({
    required String tenantId,
    required String plan,
  }) =>
      dataSource.updateTenantPlan(tenantId: tenantId, plan: plan);

  @override
  Future<void> updateTenantStatus({
    required String tenantId,
    required String status,
  }) =>
      dataSource.updateTenantStatus(tenantId: tenantId, status: status);

  @override
  Future<void> blockTenant({required String tenantId}) =>
      dataSource.blockTenant(tenantId: tenantId);

  @override
  Future<void> extendTrial({required String tenantId, required int days}) =>
      dataSource.extendTrial(tenantId: tenantId, days: days);

  @override
  Future<List<PlanEntity>> getPlans() => dataSource.getPlans();

  @override
  Future<void> updatePlan(PlanEntity plan) => dataSource.updatePlan(plan);

  @override
  Future<MasterMetrics> getMetrics() async {
    try {
      return await dataSource.getMetrics();
    } catch (_) {
      return const MasterMetrics(
        totalTenants: 0,
        activeTenants: 0,
        totalUsers: 0,
        appointmentsToday: 0,
      );
    }
  }

  @override
  Future<List<MasterUserEntity>> getUsers() => dataSource.getUsers();

  @override
  Future<PlatformStatsEntity> getPlatformStats() =>
      dataSource.getPlatformStats();

  @override
  Future<FinancialStatsEntity> getFinancialStats() async {
    try {
      return await dataSource.getFinancialStats();
    } catch (_) {
      return const FinancialStatsEntity(mrr: 0, totalRevenue: 0);
    }
  }

  @override
  Future<List<PlatformLogEntity>> getLogs({int limit = 100}) async {
    try {
      return await dataSource.getLogs(limit: limit);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<PlatformSettingsEntity> getSettings() =>
      dataSource.getSettings();

  @override
  Future<void> saveSettings(PlatformSettingsEntity settings) =>
      dataSource.saveSettings(settings);
}
