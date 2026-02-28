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

/// ===============================================================
/// PROFESSIONALS
/// ===============================================================
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
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_weekly_timegrid_usecase.dart';
import 'package:fox_link_app/modules/availability/domain/usecases/get_monthly_availability_usecase.dart';

/// ===============================================================
/// SCHEDULING
/// ===============================================================
import 'package:fox_link_app/modules/scheduling/domain/repositories/scheduling_repository.dart';
import 'package:fox_link_app/modules/scheduling/infra/repositories/scheduling_repository_impl.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/create_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/approve_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/request_reschedule_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/accept_reschedule_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/cancel_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/get_available_slots_usecase.dart';

/// ===============================================================
/// DASHBOARD
/// ===============================================================
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_admin_metrics_usecase.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_professional_metrics_usecase.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_weekly_occupation_usecase.dart';
import 'package:fox_link_app/modules/dashboard/domain/usecases/get_weekly_schedule_usecase.dart';

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
        () => InviteRemoteDataSource(
      getIt<FirebaseFirestore>(),
    ),
  );

  getIt.registerLazySingleton<InviteRepository>(
        () => InviteRepositoryImpl(
      getIt<InviteRemoteDataSource>(),
    ),
  );

  getIt.registerLazySingleton<RegisterUserUseCase>(
        () => RegisterUserUseCase(
      authRepository: getIt<AuthRepository>(),
      inviteRepository: getIt<InviteRepository>(),
      userRemote: getIt<UserRemoteDataSource>(),
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

  /// ===============================================================
  /// PROFESSIONALS
  /// ===============================================================

  getIt.registerLazySingleton<ProfessionalRemoteDataSource>(
        () => ProfessionalRemoteDataSource(),
  );

  /// ===============================================================
  /// SERVICES
  /// ===============================================================

  getIt.registerLazySingleton<ServiceRemoteDataSource>(
        () => ServiceRemoteDataSourceImpl(),
  );

  getIt.registerLazySingleton<ServiceRepository>(
        () => ServiceRepositoryImpl(
      getIt<ServiceRemoteDataSource>(),
    ),
  );

  getIt.registerLazySingleton<CreateService>(
        () => CreateService(getIt<ServiceRepository>()),
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
        () => AvailabilityRemoteDataSource(),
  );

  getIt.registerLazySingleton<AvailabilityRepository>(
        () => AvailabilityRepositoryImpl(
      getIt<AvailabilityRemoteDataSource>(),
    ),
  );

  getIt.registerLazySingleton<SaveAvailability>(
        () => SaveAvailability(
      getIt<AvailabilityRepository>(),
    ),
  );

  getIt.registerLazySingleton<GetProfessionalAvailability>(
        () => GetProfessionalAvailability(
      getIt<AvailabilityRepository>(),
    ),
  );

  getIt.registerLazySingleton<CopyWeekAvailabilityUseCase>(
        () => CopyWeekAvailabilityUseCase(
      getIt<AvailabilityRepository>(),
    ),
  );

  getIt.registerLazySingleton<GetMonthlyAvailabilityUseCase>(
        () => GetMonthlyAvailabilityUseCase(
      getIt<AvailabilityRepository>(),
    ),
  );


  /// ===============================================================
  /// SCHEDULING
  /// ===============================================================

  getIt.registerLazySingleton<SchedulingRepository>(
        () => SchedulingRepositoryImpl(
      getIt<TenantFirestore>(),
    ),
  );

  getIt.registerLazySingleton<CreateAppointmentUseCase>(
        () => CreateAppointmentUseCase(
      getIt<SchedulingRepository>(),
    ),
  );

  getIt.registerLazySingleton<ApproveAppointmentUseCase>(
        () => ApproveAppointmentUseCase(
      getIt<SchedulingRepository>(),
    ),
  );

  getIt.registerLazySingleton<RequestRescheduleUseCase>(
        () => RequestRescheduleUseCase(
      getIt<SchedulingRepository>(),
    ),
  );

  getIt.registerLazySingleton<AcceptRescheduleUseCase>(
        () => AcceptRescheduleUseCase(
      getIt<SchedulingRepository>(),
    ),
  );

  getIt.registerLazySingleton<CancelAppointmentUseCase>(
        () => CancelAppointmentUseCase(
      getIt<SchedulingRepository>(),
    ),
  );

  getIt.registerLazySingleton<GetAvailableSlotsUseCase>(
        () => GetAvailableSlotsUseCase(
      availabilityRepository: getIt(),
      schedulingRepository: getIt(),
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
    ),
  );

  getIt.registerLazySingleton<GetWeeklyOccupationUseCase>(
        () => GetWeeklyOccupationUseCase(
      getIt<SchedulingRepository>(),
    ),
  );

  getIt.registerLazySingleton<GetWeeklyScheduleUseCase>(
        () => GetWeeklyScheduleUseCase(
      getIt<SchedulingRepository>(),
    ),
  );

  getIt.registerLazySingleton<GetWeeklyTimeGridUseCase>(
        () => GetWeeklyTimeGridUseCase(
      getIt<SchedulingRepository>(),
    ),
  );

}