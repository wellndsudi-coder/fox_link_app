import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ===============================================================
/// CORE
/// ===============================================================
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/database/tenant_firestore.dart';

/// ===============================================================
/// AUTH
/// ===============================================================
import 'package:fox_link_app/modules/auth/infra/datasources/auth_remote_datasource.dart';
import 'package:fox_link_app/modules/auth/infra/datasources/invite_remote_datasource.dart';
import 'package:fox_link_app/modules/auth/infra/repositories/auth_repository_impl.dart';
import 'package:fox_link_app/modules/auth/infra/repositories/invite_repository_impl.dart';
import 'package:fox_link_app/modules/auth/domain/repositories/auth_repository.dart';
import 'package:fox_link_app/modules/auth/domain/repositories/invite_repository.dart';
import 'package:fox_link_app/modules/auth/domain/usecases/register_user_usecase.dart';

/// ===============================================================
/// USERS / TENANT
/// ===============================================================
import 'package:fox_link_app/modules/users/infra/datasources/user_remote_datasource.dart';
import 'package:fox_link_app/modules/tenant/infra/datasources/tenant_remote_datasource.dart';
import 'package:fox_link_app/modules/users/domain/repositories/user_repository.dart';
import 'package:fox_link_app/modules/users/infra/repositories/user_repository_impl.dart';
import 'package:fox_link_app/modules/users/domain/usecases/get_users_by_ids_usecase.dart';
import 'package:fox_link_app/modules/professionals/infra/datasources/professional_remote_datasource.dart';

/// ===============================================================
/// SERVICES
/// ===============================================================
import 'package:fox_link_app/modules/services/domain/usecases/create_service.dart';
import 'package:fox_link_app/modules/services/domain/usecases/update_service.dart';
import 'package:fox_link_app/modules/services/domain/usecases/get_services.dart';
import 'package:fox_link_app/modules/services/domain/usecases/toggle_service_active.dart';
import 'package:fox_link_app/modules/services/domain/usecases/delete_service.dart';
import 'package:fox_link_app/modules/services/domain/repositories/service_repository.dart';
import 'package:fox_link_app/modules/services/infra/datasources/service_remote_datasource.dart';
import 'package:fox_link_app/modules/services/infra/repositories/service_repository_impl.dart';

/// ===============================================================
/// AVAILABILITY
/// ===============================================================
import 'package:fox_link_app/modules/availability/domain/repositories/availability_repository.dart';
import 'package:fox_link_app/modules/availability/infra/repositories/availability_repository_impl.dart';
import 'package:fox_link_app/modules/availability/infra/datasources/availability_remote_datasource.dart';
import 'package:fox_link_app/modules/availability/domain/usecases/save_availability.dart';
import 'package:fox_link_app/modules/availability/domain/usecases/get_professional_availability.dart';
import 'package:fox_link_app/modules/availability/domain/usecases/copy_week_availability_usecase.dart';
import 'package:fox_link_app/modules/availability/domain/usecases/get_monthly_availability_usecase.dart';

/// ===============================================================
/// SCHEDULING
/// ===============================================================
import 'package:fox_link_app/modules/scheduling/domain/repositories/scheduling_repository.dart';
import 'package:fox_link_app/modules/scheduling/domain/repositories/manual_block_repository.dart';
import 'package:fox_link_app/modules/scheduling/infra/repositories/scheduling_repository_impl.dart';
import 'package:fox_link_app/modules/scheduling/infra/repositories/manual_block_repository_impl.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/create_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/approve_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/request_reschedule_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/accept_reschedule_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/cancel_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/get_available_slots_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/get_client_appointments_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/get_manual_blocks_by_period_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/save_manual_block_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/delete_manual_block_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/update_appointment_time_usecase.dart';

/// ===============================================================
/// DASHBOARD
/// ===============================================================
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_admin_metrics_usecase.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_professional_metrics_usecase.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_today_agenda_usecase.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_top_services_usecase.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_weekly_revenue_usecase.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_weekly_occupation_usecase.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_weekly_schedule_usecase.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_weekly_timegrid_usecase.dart';
import 'package:fox_link_app/modules/subscription/domain/usecases/check_trial_expired_usecase.dart';
import 'package:fox_link_app/modules/subscription/domain/usecases/check_plan_limit_usecase.dart';
import 'package:fox_link_app/modules/subscription/domain/usecases/update_tenant_plan_usecase.dart';
import 'package:fox_link_app/modules/tenant/domain/usecases/get_white_label_config_usecase.dart';
import 'package:fox_link_app/core/white_label/white_label_service.dart';

final getIt = GetIt.instance;

Future<void> setupInjection() async {

  /// ===============================================================
  /// CORE
  /// ===============================================================

  getIt.registerLazySingleton<TenantSession>(() => TenantSession());

  getIt.registerLazySingleton<FirebaseFirestore>(
        () => FirebaseFirestore.instance,
  );

  getIt.registerLazySingleton<TenantFirestore>(
        () => TenantFirestore(
      getIt<FirebaseFirestore>(),
      getIt<TenantSession>(),
    ),
  );

  /// ===============================================================
  /// AUTH
  /// ===============================================================

  getIt.registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSource(),
  );

  getIt.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
      getIt<AuthRemoteDataSource>(),
    ),
  );

  getIt.registerLazySingleton<InviteRemoteDataSource>(
        () => InviteRemoteDataSource(getIt()),
  );

  getIt.registerLazySingleton<InviteRepository>(
        () => InviteRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton<RegisterUserUseCase>(
        () => RegisterUserUseCase(
      authRepository: getIt<AuthRepository>(),
      inviteRepository: getIt<InviteRepository>(),
      userRemote: getIt<UserRemoteDataSource>(),
      professionalRemote: getIt<ProfessionalRemoteDataSource>(),
    ),
  );

  /// ===============================================================
  /// USERS / TENANT
  /// ===============================================================

  getIt.registerLazySingleton<UserRemoteDataSource>(
        () => UserRemoteDataSource(),
  );

  getIt.registerLazySingleton<TenantRemoteDataSource>(
        () => TenantRemoteDataSource(),
  );

  getIt.registerLazySingleton<UserRepository>(
        () => UserRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton<GetUsersByIdsUseCase>(
        () => GetUsersByIdsUseCase(getIt()),
  );

  /// ===============================================================
  /// SUBSCRIPTION (antes de ProfessionalRemoteDataSource que usa CheckTrialExpiredUseCase)
  /// ===============================================================

  getIt.registerLazySingleton<CheckTrialExpiredUseCase>(
        () => CheckTrialExpiredUseCase(getIt<TenantRemoteDataSource>()),
  );

  getIt.registerLazySingleton<CheckPlanLimitUseCase>(
        () => CheckPlanLimitUseCase(getIt<TenantRemoteDataSource>()),
  );

  getIt.registerLazySingleton<UpdateTenantPlanUseCase>(
        () => UpdateTenantPlanUseCase(getIt<TenantRemoteDataSource>()),
  );

  getIt.registerLazySingleton<ProfessionalRemoteDataSource>(
        () => ProfessionalRemoteDataSource(),
  );

  getIt.registerLazySingleton<GetWhiteLabelConfigUseCase>(
        () => GetWhiteLabelConfigUseCase(getIt<TenantRemoteDataSource>()),
  );

  getIt.registerLazySingleton<WhiteLabelService>(
        () => WhiteLabelService(getIt<GetWhiteLabelConfigUseCase>()),
  );

  /// ===============================================================
  /// SERVICES
  /// ===============================================================

  getIt.registerLazySingleton<ServiceRemoteDataSource>(
        () => ServiceRemoteDataSourceImpl(
      getIt<TenantFirestore>(),
    ),
  );

  getIt.registerLazySingleton<ServiceRepository>(
        () => ServiceRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton<CreateService>(
        () => CreateService(
      getIt<ServiceRepository>(),
      checkPlanLimit: getIt<CheckPlanLimitUseCase>(),
      checkTrialExpired: getIt<CheckTrialExpiredUseCase>(),
      getServices: getIt<GetServices>(),
    ),
  );

  getIt.registerLazySingleton<UpdateService>(
        () => UpdateService(getIt<ServiceRepository>()),
  );

  getIt.registerLazySingleton<GetServices>(
        () => GetServices(getIt<ServiceRepository>()),
  );

  getIt.registerLazySingleton<ToggleServiceActive>(
        () => ToggleServiceActive(getIt<ServiceRepository>()),
  );

  getIt.registerLazySingleton<DeleteService>(
        () => DeleteService(getIt<ServiceRepository>()),
  );

  /// ===============================================================
  /// AVAILABILITY
  /// ===============================================================

  getIt.registerLazySingleton<AvailabilityRemoteDataSource>(
        () => AvailabilityRemoteDataSource(
      getIt<TenantFirestore>(),
    ),
  );

  getIt.registerLazySingleton<AvailabilityRepository>(
        () => AvailabilityRepositoryImpl(
      getIt<AvailabilityRemoteDataSource>(),
    ),
  );

  getIt.registerLazySingleton<SaveAvailability>(
        () => SaveAvailability(getIt<AvailabilityRepository>()),
  );

  getIt.registerLazySingleton<GetProfessionalAvailability>(
        () => GetProfessionalAvailability(getIt<AvailabilityRepository>()),
  );

  getIt.registerLazySingleton<CopyWeekAvailabilityUseCase>(
        () => CopyWeekAvailabilityUseCase(getIt<AvailabilityRepository>()),
  );

  getIt.registerLazySingleton<GetMonthlyAvailabilityUseCase>(
        () => GetMonthlyAvailabilityUseCase(getIt<AvailabilityRepository>()),
  );

  /// ===============================================================
  /// SCHEDULING
  /// ===============================================================

  getIt.registerLazySingleton<SchedulingRepository>(
        () => SchedulingRepositoryImpl(
      getIt<TenantFirestore>(),
    ),
  );

  getIt.registerLazySingleton<ManualBlockRepository>(
        () => ManualBlockRepositoryImpl(getIt<TenantFirestore>()),
  );

  getIt.registerLazySingleton<CreateAppointmentUseCase>(
        () => CreateAppointmentUseCase(getIt<SchedulingRepository>()),
  );

  getIt.registerLazySingleton<ApproveAppointmentUseCase>(
        () => ApproveAppointmentUseCase(getIt<SchedulingRepository>()),
  );

  getIt.registerLazySingleton<RequestRescheduleUseCase>(
        () => RequestRescheduleUseCase(getIt<SchedulingRepository>()),
  );

  getIt.registerLazySingleton<AcceptRescheduleUseCase>(
        () => AcceptRescheduleUseCase(getIt<SchedulingRepository>()),
  );

  getIt.registerLazySingleton<CancelAppointmentUseCase>(
        () => CancelAppointmentUseCase(getIt<SchedulingRepository>()),
  );

  getIt.registerLazySingleton<GetAvailableSlotsUseCase>(
        () => GetAvailableSlotsUseCase(
      availabilityRepository: getIt<AvailabilityRepository>(),
      schedulingRepository: getIt<SchedulingRepository>(),
      manualBlockRepository: getIt<ManualBlockRepository>(),
    ),
  );

  getIt.registerLazySingleton<GetClientAppointmentsUseCase>(
        () => GetClientAppointmentsUseCase(getIt<SchedulingRepository>()),
  );

  getIt.registerLazySingleton<GetManualBlocksByPeriodUseCase>(
        () => GetManualBlocksByPeriodUseCase(getIt<ManualBlockRepository>()),
  );

  getIt.registerLazySingleton<SaveManualBlockUseCase>(
        () => SaveManualBlockUseCase(getIt<ManualBlockRepository>()),
  );

  getIt.registerLazySingleton<DeleteManualBlockUseCase>(
        () => DeleteManualBlockUseCase(getIt<ManualBlockRepository>()),
  );

  getIt.registerLazySingleton<UpdateAppointmentTimeUseCase>(
        () => UpdateAppointmentTimeUseCase(
      schedulingRepository: getIt<SchedulingRepository>(),
      manualBlockRepository: getIt<ManualBlockRepository>(),
    ),
  );

  /// ===============================================================
  /// DASHBOARD
  /// ===============================================================

  getIt.registerLazySingleton<GetAdminMetricsUseCase>(
        () => GetAdminMetricsUseCase(
      getIt<TenantFirestore>(),
    ),
  );

  getIt.registerLazySingleton<GetProfessionalMetricsUseCase>(
        () => GetProfessionalMetricsUseCase(
      getIt<TenantFirestore>(),
      getIt<TenantSession>(),
    ),
  );

  getIt.registerLazySingleton<GetWeeklyOccupationUseCase>(
        () => GetWeeklyOccupationUseCase(getIt()),
  );

  getIt.registerLazySingleton<GetWeeklyScheduleUseCase>(
        () => GetWeeklyScheduleUseCase(getIt()),
  );

  getIt.registerLazySingleton<GetWeeklyTimeGridUseCase>(
        () => GetWeeklyTimeGridUseCase(
      getIt<SchedulingRepository>(),
      userRepository: getIt<UserRepository>(),
      serviceRepository: getIt<ServiceRepository>(),
    ),
  );

  getIt.registerLazySingleton<GetTodayAgendaUseCase>(
        () => GetTodayAgendaUseCase(
      getIt<SchedulingRepository>(),
      getIt<ProfessionalRemoteDataSource>(),
      getIt<TenantSession>(),
      userRepository: getIt<UserRepository>(),
      serviceRepository: getIt<ServiceRepository>(),
    ),
  );

  getIt.registerLazySingleton<GetTopServicesUseCase>(
        () => GetTopServicesUseCase(
      getIt<SchedulingRepository>(),
      getIt<ServiceRepository>(),
      getIt<TenantSession>(),
    ),
  );

  getIt.registerLazySingleton<GetWeeklyRevenueUseCase>(
    () => GetWeeklyRevenueUseCase(getIt<TenantFirestore>()),
  );
}