import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ===============================================================
/// CORE
/// ===============================================================
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/auth/token_manager.dart';
import 'package:fox_link_app/core/auth/auth_state.dart';
import 'package:fox_link_app/core/auth/auth_api.dart';
import 'package:fox_link_app/core/auth/session_manager.dart';
import 'package:fox_link_app/core/auth/auth_interceptor.dart';
import 'package:fox_link_app/core/auth/infra/auth_api_impl.dart';
import 'package:fox_link_app/features/login/domain/remember_me_preference.dart';
import 'package:fox_link_app/features/login/domain/login_use_case.dart';
import 'package:fox_link_app/core/database/tenant_firestore.dart';
import 'package:fox_link_app/core/notification/fcm_token_service.dart';
import 'package:fox_link_app/core/storage/acknowledged_cancellations_storage.dart';

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
import 'package:fox_link_app/modules/professionals/domain/usecases/get_professionals_by_service_usecase.dart';

/// ===============================================================
/// SERVICES
/// ===============================================================
import 'package:fox_link_app/modules/services/domain/usecases/create_service.dart';
import 'package:fox_link_app/modules/services/domain/usecases/update_service.dart';
import 'package:fox_link_app/modules/services/domain/usecases/get_services.dart';
import 'package:fox_link_app/modules/services/domain/usecases/toggle_service_active.dart';
import 'package:fox_link_app/modules/services/domain/usecases/delete_service.dart';
import 'package:fox_link_app/modules/services/domain/usecases/get_service_categories_usecase.dart';
import 'package:fox_link_app/modules/services/domain/usecases/create_service_category_usecase.dart';
import 'package:fox_link_app/modules/services/domain/usecases/update_service_category_usecase.dart';
import 'package:fox_link_app/modules/services/domain/usecases/delete_service_category_usecase.dart';
import 'package:fox_link_app/modules/services/domain/usecases/get_addons_for_base_service_usecase.dart';
import 'package:fox_link_app/modules/services/domain/repositories/service_repository.dart';
import 'package:fox_link_app/modules/services/domain/repositories/service_category_repository.dart';
import 'package:fox_link_app/modules/services/infra/datasources/service_remote_datasource.dart';
import 'package:fox_link_app/modules/services/infra/repositories/service_repository_impl.dart';
import 'package:fox_link_app/modules/services/infra/datasources/service_category_remote_datasource.dart';
import 'package:fox_link_app/modules/services/infra/repositories/service_category_repository_impl.dart';

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
import 'package:fox_link_app/modules/scheduling/domain/usecases/reject_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/complete_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/get_available_slots_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/get_client_appointments_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/get_clients_by_professional_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/get_manual_blocks_by_period_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/get_monthly_agenda_stats_usecase.dart';
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
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_weekly_appointments_usecase.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_tenant_weekly_occupation_usecase.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_top_professionals_usecase.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_client_retention_usecase.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_occupancy_rate_usecase.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_weekly_occupation_usecase.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_weekly_schedule_usecase.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_weekly_timegrid_usecase.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_client_appointments_display_usecase.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/stream_client_appointments_display_usecase.dart';
import 'package:fox_link_app/modules/subscription/domain/usecases/check_trial_expired_usecase.dart';
import 'package:fox_link_app/modules/subscription/domain/usecases/check_plan_limit_usecase.dart';
import 'package:fox_link_app/modules/subscription/domain/usecases/update_tenant_plan_usecase.dart';
import 'package:fox_link_app/modules/tenant/domain/usecases/get_white_label_config_usecase.dart';
import 'package:fox_link_app/modules/tenant/domain/usecases/get_tenant_config_usecase.dart';
import 'package:fox_link_app/core/white_label/white_label_service.dart';

/// ===============================================================
/// BOOKING INTELLIGENCE
/// ===============================================================
import 'package:fox_link_app/modules/booking_intelligence/domain/repositories/waiting_list_repository.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/repositories/queue_repository.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/repositories/favorites_repository.dart';
import 'package:fox_link_app/modules/booking_intelligence/infra/datasources/waiting_list_remote_datasource.dart';
import 'package:fox_link_app/modules/booking_intelligence/infra/datasources/queue_remote_datasource.dart';
import 'package:fox_link_app/modules/booking_intelligence/infra/datasources/favorites_remote_datasource.dart';
import 'package:fox_link_app/modules/booking_intelligence/infra/repositories/waiting_list_repository_impl.dart';
import 'package:fox_link_app/modules/booking_intelligence/infra/repositories/queue_repository_impl.dart';
import 'package:fox_link_app/modules/booking_intelligence/infra/repositories/favorites_repository_impl.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/usecases/get_first_available_slot_usecase.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/usecases/find_best_fit_slot_usecase.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/usecases/repeat_last_appointment_usecase.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/usecases/smart_booking_suggestion_usecase.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/usecases/get_soonest_slots_usecase.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/usecases/join_waiting_list_usecase.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/usecases/confirm_waiting_list_slot_usecase.dart';
import 'package:fox_link_app/modules/waitlist/domain/repositories/waitlist_repository.dart';
import 'package:fox_link_app/modules/waitlist/domain/usecases/offer_waitlist_slot_usecase.dart';
import 'package:fox_link_app/modules/waitlist/domain/usecases/stream_weekly_waitlist_usecase.dart';
import 'package:fox_link_app/modules/waitlist/infra/datasources/waitlist_remote_datasource.dart';
import 'package:fox_link_app/modules/waitlist/infra/repositories/waitlist_repository_impl.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/usecases/get_queue_status_usecase.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/usecases/join_queue_usecase.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/usecases/quick_reschedule_usecase.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/usecases/get_client_history_usecase.dart';

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

  getIt.registerLazySingleton<FcmTokenService>(() => FcmTokenService());

  /// ===============================================================
  /// CORE AUTH (Token / Session)
  /// ===============================================================

  getIt.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSource());

  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  getIt.registerLazySingleton<TokenManager>(() => TokenManager());
  getIt.registerLazySingleton<AuthState>(() => AuthState());

  final dio = Dio();
  getIt.registerLazySingleton<AuthApi>(() => AuthApiImpl());
  getIt.registerLazySingleton<SessionManager>(
    () => SessionManager(
      tokenManager: getIt<TokenManager>(),
      authApi: getIt<AuthApi>(),
      tenantSession: getIt<TenantSession>(),
      authState: getIt<AuthState>(),
      authRemote: getIt<AuthRemoteDataSource>(),
    ),
  );
  dio.interceptors.add(
    AuthInterceptor(
      tokenManager: getIt<TokenManager>(),
      sessionManager: getIt<SessionManager>(),
      dio: dio,
    ),
  );
  getIt.registerSingleton<Dio>(dio);

  getIt.registerLazySingleton<RememberMePreference>(
    () => RememberMePreference(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(
      authApi: getIt<AuthApi>(),
      tokenManager: getIt<TokenManager>(),
      rememberMePreference: getIt<RememberMePreference>(),
    ),
  );

  /// ===============================================================
  /// AUTH (Firebase)
  /// ===============================================================

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

  getIt.registerLazySingleton<GetProfessionalsByServiceUseCase>(
        () => GetProfessionalsByServiceUseCase(getIt<ProfessionalRemoteDataSource>()),
  );

  getIt.registerLazySingleton<GetWhiteLabelConfigUseCase>(
        () => GetWhiteLabelConfigUseCase(getIt<TenantRemoteDataSource>()),
  );

  getIt.registerLazySingleton<GetTenantConfigUseCase>(
        () => GetTenantConfigUseCase(getIt<TenantRemoteDataSource>()),
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

  getIt.registerLazySingleton<ServiceCategoryRemoteDataSource>(
        () => ServiceCategoryRemoteDataSourceImpl(getIt<TenantFirestore>()),
  );

  getIt.registerLazySingleton<ServiceCategoryRepository>(
        () => ServiceCategoryRepositoryImpl(getIt<ServiceCategoryRemoteDataSource>()),
  );

  getIt.registerLazySingleton<GetServiceCategoriesUseCase>(
        () => GetServiceCategoriesUseCase(getIt<ServiceCategoryRepository>()),
  );

  getIt.registerLazySingleton<CreateServiceCategoryUseCase>(
        () => CreateServiceCategoryUseCase(getIt<ServiceCategoryRepository>()),
  );

  getIt.registerLazySingleton<UpdateServiceCategoryUseCase>(
        () => UpdateServiceCategoryUseCase(getIt<ServiceCategoryRepository>()),
  );

  getIt.registerLazySingleton<DeleteServiceCategoryUseCase>(
        () => DeleteServiceCategoryUseCase(getIt<ServiceCategoryRepository>()),
  );

  getIt.registerLazySingleton<GetAddonsForBaseServiceUseCase>(
        () => GetAddonsForBaseServiceUseCase(getIt<ServiceRepository>()),
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

  getIt.registerLazySingleton<RejectAppointmentUseCase>(
        () => RejectAppointmentUseCase(getIt<SchedulingRepository>()),
  );

  getIt.registerLazySingleton<CompleteAppointmentUseCase>(
        () => CompleteAppointmentUseCase(getIt<SchedulingRepository>()),
  );

  getIt.registerLazySingleton<GetAvailableSlotsUseCase>(
        () => GetAvailableSlotsUseCase(
      availabilityRepository: getIt<AvailabilityRepository>(),
      schedulingRepository: getIt<SchedulingRepository>(),
      manualBlockRepository: getIt<ManualBlockRepository>(),
      getTenantConfigUseCase: getIt<GetTenantConfigUseCase>(),
      tenantSession: getIt<TenantSession>(),
    ),
  );

  getIt.registerLazySingleton<AcknowledgedCancellationsStorage>(
    () => AcknowledgedCancellationsStorage(),
  );

  getIt.registerLazySingleton<GetClientsByProfessionalUseCase>(
    () => GetClientsByProfessionalUseCase(
      schedulingRepository: getIt<SchedulingRepository>(),
      userRepository: getIt<UserRepository>(),
    ),
  );

  getIt.registerLazySingleton<GetClientAppointmentsUseCase>(
        () => GetClientAppointmentsUseCase(getIt<SchedulingRepository>()),
  );

  getIt.registerLazySingleton<GetClientAppointmentsDisplayUseCase>(
    () => GetClientAppointmentsDisplayUseCase(
      schedulingRepository: getIt<SchedulingRepository>(),
      serviceRepository: getIt<ServiceRepository>(),
      professionalDataSource: getIt<ProfessionalRemoteDataSource>(),
      tenantSession: getIt<TenantSession>(),
    ),
  );

  getIt.registerLazySingleton<StreamClientAppointmentsDisplayUseCase>(
    () => StreamClientAppointmentsDisplayUseCase(
      schedulingRepository: getIt<SchedulingRepository>(),
      serviceRepository: getIt<ServiceRepository>(),
      professionalDataSource: getIt<ProfessionalRemoteDataSource>(),
      tenantSession: getIt<TenantSession>(),
    ),
  );

  getIt.registerLazySingleton<GetManualBlocksByPeriodUseCase>(
        () => GetManualBlocksByPeriodUseCase(getIt<ManualBlockRepository>()),
  );

  getIt.registerLazySingleton<GetMonthlyAgendaStatsUseCase>(
        () => GetMonthlyAgendaStatsUseCase(
      availabilityRepository: getIt<AvailabilityRepository>(),
      schedulingRepository: getIt<SchedulingRepository>(),
      manualBlockRepository: getIt<ManualBlockRepository>(),
    ),
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

  getIt.registerLazySingleton<GetWeeklyAppointmentsUseCase>(
    () => GetWeeklyAppointmentsUseCase(getIt<TenantFirestore>()),
  );

  getIt.registerLazySingleton<GetTenantWeeklyOccupationUseCase>(
    () => GetTenantWeeklyOccupationUseCase(getIt<TenantFirestore>()),
  );

  getIt.registerLazySingleton<GetTopProfessionalsUseCase>(
    () => GetTopProfessionalsUseCase(
      getIt<TenantFirestore>(),
      getIt<TenantSession>(),
    ),
  );

  getIt.registerLazySingleton<GetClientRetentionUseCase>(
    () => GetClientRetentionUseCase(getIt<TenantFirestore>()),
  );

  getIt.registerLazySingleton<GetOccupancyRateUseCase>(
    () => GetOccupancyRateUseCase(getIt<TenantFirestore>()),
  );

  /// ===============================================================
  /// BOOKING INTELLIGENCE
  /// ===============================================================

  getIt.registerLazySingleton<WaitingListRemoteDataSource>(
    () => WaitingListRemoteDataSourceImpl(getIt<TenantFirestore>()),
  );
  getIt.registerLazySingleton<QueueRemoteDataSource>(
    () => QueueRemoteDataSourceImpl(getIt<TenantFirestore>()),
  );
  getIt.registerLazySingleton<FavoritesRemoteDataSource>(
    () => FavoritesRemoteDataSourceImpl(getIt<TenantFirestore>()),
  );

  getIt.registerLazySingleton<WaitingListRepository>(
    () => WaitingListRepositoryImpl(getIt<WaitingListRemoteDataSource>()),
  );
  getIt.registerLazySingleton<QueueRepository>(
    () => QueueRepositoryImpl(getIt<QueueRemoteDataSource>()),
  );
  getIt.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepositoryImpl(getIt<FavoritesRemoteDataSource>()),
  );

  getIt.registerLazySingleton<GetFirstAvailableSlotUseCase>(
    () => GetFirstAvailableSlotUseCase(
      getProfessionalsByServiceUseCase: getIt<GetProfessionalsByServiceUseCase>(),
      serviceRepository: getIt<ServiceRepository>(),
      getAvailableSlotsUseCase: getIt<GetAvailableSlotsUseCase>(),
      tenantSession: getIt<TenantSession>(),
    ),
  );
  getIt.registerLazySingleton<FindBestFitSlotUseCase>(
    () => FindBestFitSlotUseCase(
      availabilityRepository: getIt<AvailabilityRepository>(),
      schedulingRepository: getIt<SchedulingRepository>(),
      manualBlockRepository: getIt<ManualBlockRepository>(),
    ),
  );
  getIt.registerLazySingleton<RepeatLastAppointmentUseCase>(
    () => RepeatLastAppointmentUseCase(
      schedulingRepository: getIt<SchedulingRepository>(),
      getFirstAvailableSlotUseCase: getIt<GetFirstAvailableSlotUseCase>(),
    ),
  );
  getIt.registerLazySingleton<SmartBookingSuggestionUseCase>(
    () => SmartBookingSuggestionUseCase(
      schedulingRepository: getIt<SchedulingRepository>(),
      favoritesRepository: getIt<FavoritesRepository>(),
      getFirstAvailableSlotUseCase: getIt<GetFirstAvailableSlotUseCase>(),
    ),
  );
  getIt.registerLazySingleton<GetSoonestSlotsUseCase>(
    () => GetSoonestSlotsUseCase(
      professionalDataSource: getIt<ProfessionalRemoteDataSource>(),
      getProfessionalsByServiceUseCase: getIt<GetProfessionalsByServiceUseCase>(),
      serviceRepository: getIt<ServiceRepository>(),
      getAvailableSlotsUseCase: getIt<GetAvailableSlotsUseCase>(),
      tenantSession: getIt<TenantSession>(),
    ),
  );
  getIt.registerLazySingleton<JoinWaitingListUseCase>(
    () => JoinWaitingListUseCase(getIt<WaitingListRepository>()),
  );
  getIt.registerLazySingleton<ConfirmWaitingListSlotUseCase>(
    () => ConfirmWaitingListSlotUseCase(
      schedulingRepo: getIt<SchedulingRepository>(),
      waitingListRepo: getIt<WaitingListRepository>(),
      serviceRepo: getIt<ServiceRepository>(),
    ),
  );
  getIt.registerLazySingleton<GetQueueStatusUseCase>(
    () => GetQueueStatusUseCase(getIt<QueueRepository>()),
  );
  getIt.registerLazySingleton<JoinQueueUseCase>(
    () => JoinQueueUseCase(getIt<QueueRepository>()),
  );
  getIt.registerLazySingleton<QuickRescheduleUseCase>(
    () => QuickRescheduleUseCase(
      schedulingRepository: getIt<SchedulingRepository>(),
      getAvailableSlotsUseCase: getIt<GetAvailableSlotsUseCase>(),
      serviceRepository: getIt<ServiceRepository>(),
      tenantSession: getIt<TenantSession>(),
    ),
  );
  getIt.registerLazySingleton<GetClientHistoryUseCase>(
    () => GetClientHistoryUseCase(
      schedulingRepository: getIt<SchedulingRepository>(),
      serviceRepository: getIt<ServiceRepository>(),
      professionalDataSource: getIt<ProfessionalRemoteDataSource>(),
      tenantSession: getIt<TenantSession>(),
    ),
  );

  /// ===============================================================
  /// WAITLIST
  /// ===============================================================
  getIt.registerLazySingleton<WaitlistRemoteDataSource>(
    () => WaitlistRemoteDataSourceImpl(
      getIt<TenantFirestore>(),
      getIt<TenantSession>(),
    ),
  );
  getIt.registerLazySingleton<WaitlistRepository>(
    () => WaitlistRepositoryImpl(getIt<WaitlistRemoteDataSource>()),
  );
  getIt.registerLazySingleton<StreamWeeklyWaitlistUseCase>(
    () => StreamWeeklyWaitlistUseCase(getIt<WaitlistRepository>()),
  );
  getIt.registerLazySingleton<OfferWaitlistSlotUseCase>(
    () => OfferWaitlistSlotUseCase(
      waitlistRepo: getIt<WaitlistRepository>(),
      getSlotsUseCase: getIt<GetAvailableSlotsUseCase>(),
      createAppointmentUseCase: getIt<CreateAppointmentUseCase>(),
      serviceRepo: getIt<ServiceRepository>(),
      tenantSession: getIt<TenantSession>(),
    ),
  );
}