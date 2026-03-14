import 'package:flutter/foundation.dart';
import '../../domain/entities/plan_entity.dart';
import '../../domain/entities/tenant_entity.dart';
import '../../domain/entities/financial_stats_entity.dart';
import '../../domain/entities/platform_log_entity.dart';
import '../../domain/entities/platform_settings_entity.dart';
import '../../domain/entities/platform_stats_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/master_repository.dart';
import '../../domain/usecases/get_financial_stats_usecase.dart';
import '../../domain/usecases/get_logs_usecase.dart';
import '../../domain/usecases/get_master_metrics_usecase.dart';
import '../../domain/usecases/get_platform_stats_usecase.dart';
import '../../domain/usecases/get_plans_usecase.dart';
import '../../domain/usecases/get_tenants_usecase.dart';
import '../../domain/usecases/get_users_usecase.dart';
import '../../domain/usecases/update_plan_usecase.dart';
import '../../domain/usecases/block_tenant_usecase.dart';
import '../../domain/usecases/extend_trial_usecase.dart';
import '../../domain/usecases/update_tenant_plan_usecase.dart';
import '../../domain/usecases/update_tenant_status_usecase.dart';
import '../../domain/usecases/get_settings_usecase.dart';
import '../../domain/usecases/save_settings_usecase.dart';

class MasterController extends ChangeNotifier {
  final GetTenantsUseCase getTenants;
  final MasterUpdateTenantPlanUseCase updateTenantPlan;
  final UpdateTenantStatusUseCase updateTenantStatus;
  final BlockTenantUseCase blockTenantUseCase;
  final ExtendTrialUseCase extendTrialUseCase;
  final GetPlansUseCase getPlans;
  final UpdatePlanUseCase updatePlanUseCase;
  final GetMasterMetricsUseCase getMetrics;
  final GetMasterUsersUseCase getUsers;
  final GetPlatformStatsUseCase getPlatformStats;
  final GetFinancialStatsUseCase getFinancialStats;
  final GetLogsUseCase getLogs;
  final GetSettingsUseCase getSettings;
  final SaveSettingsUseCase saveSettingsUseCase;

  MasterController({
    required this.getTenants,
    required this.updateTenantPlan,
    required this.updateTenantStatus,
    required this.blockTenantUseCase,
    required this.extendTrialUseCase,
    required this.getPlans,
    required this.updatePlanUseCase,
    required this.getMetrics,
    required this.getUsers,
    required this.getPlatformStats,
    required this.getFinancialStats,
    required this.getLogs,
    required this.getSettings,
    required this.saveSettingsUseCase,
  });

  bool _loading = false;
  bool get loading => _loading;

  List<TenantEntity> _tenants = [];
  List<TenantEntity> get tenants => _tenants;

  List<PlanEntity> _plans = [];
  List<PlanEntity> get plans => _plans;

  MasterMetrics? _metrics;
  MasterMetrics? get metrics => _metrics;

  List<MasterUserEntity> _users = [];
  List<MasterUserEntity> get users => _users;

  PlatformStatsEntity? _platformStats;
  PlatformStatsEntity? get platformStats => _platformStats;

  FinancialStatsEntity? _financialStats;
  FinancialStatsEntity? get financialStats => _financialStats;

  List<PlatformLogEntity> _logs = [];
  List<PlatformLogEntity> get logs => _logs;

  PlatformSettingsEntity? _settings;
  PlatformSettingsEntity? get settings => _settings;

  Future<void> loadTenants() async {
    _loading = true;
    notifyListeners();
    try {
      _tenants = await getTenants();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadPlans() async {
    _loading = true;
    notifyListeners();
    try {
      _plans = await getPlans();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMetrics() async {
    _loading = true;
    notifyListeners();
    try {
      _metrics = await getMetrics();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateTenantPlanById(String tenantId, String plan) async {
    await updateTenantPlan(tenantId: tenantId, plan: plan);
    await loadTenants();
    await loadMetrics();
  }

  Future<void> updatePlan(PlanEntity plan) async {
    await updatePlanUseCase(plan);
    await loadPlans();
  }

  Future<void> updateStatus(String tenantId, String status) async {
    await updateTenantStatus(tenantId: tenantId, status: status);
    await loadTenants();
    await loadMetrics();
  }

  Future<void> blockTenant(String tenantId) async {
    await blockTenantUseCase.call(tenantId);
    await loadTenants();
    await loadMetrics();
  }

  Future<void> extendTrial(String tenantId, int days) async {
    await extendTrialUseCase.call(tenantId: tenantId, days: days);
    await loadTenants();
  }

  Future<void> loadUsers() async {
    _loading = true;
    notifyListeners();
    try {
      _users = await getUsers();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadPlatformStats() async {
    _loading = true;
    notifyListeners();
    try {
      _platformStats = await getPlatformStats();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadFinancialStats() async {
    _loading = true;
    notifyListeners();
    try {
      _financialStats = await getFinancialStats();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadLogs() async {
    _loading = true;
    notifyListeners();
    try {
      _logs = await getLogs();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadSettings() async {
    _loading = true;
    notifyListeners();
    try {
      _settings = await getSettings();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> saveSettings(PlatformSettingsEntity s) async {
    await saveSettingsUseCase.call(s);
    _settings = s;
    notifyListeners();
  }
}
