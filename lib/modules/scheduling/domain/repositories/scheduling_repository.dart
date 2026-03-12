import '../entities/appointment.dart';

abstract class SchedulingRepository {

  // ==========================================================
  // 🔹 Obter por ID
  // ==========================================================
  Future<Appointment?> getById(String appointmentId);

  // ==========================================================
  // 🔹 Criar agendamento
  // ==========================================================
  Future<void> create(Appointment appointment);

  // ==========================================================
  // 🔹 Atualizar horário (drag/resize)
  // ==========================================================
  Future<void> updateAppointmentTime({
    required String appointmentId,
    required DateTime newStart,
    required DateTime newEnd,
  });

  // ==========================================================
  // 🔹 Atualizar status
  // ==========================================================
  Future<void> updateStatus(
      String appointmentId,
      AppointmentStatus status,
      );

  Future<List<Appointment>> getByProfessionalAndDateRange({
    required String professionalId,
    required DateTime start,
    required DateTime end,
  });

  // ==========================================================
  // 🔹 Buscar por profissional + data
  // ==========================================================
  Future<List<Appointment>> getByProfessionalAndDate({
    required String professionalId,
    required DateTime date,
  });

  // ==========================================================
  // 🔹 Buscar aprovados por profissional e data
  // ==========================================================
  Future<List<Appointment>> getApprovedByProfessionalAndDate({
    required String professionalId,
    required DateTime date,
  });

  // ==========================================================
  // 🔹 Buscar pendentes
  // ==========================================================
  Future<List<Appointment>> getPendingByProfessional(
      String professionalId,
      );

  Future<List<Appointment>> getByTenantAndDate(DateTime date);

  Future<List<Appointment>> getByTenantAndPeriod({
    required DateTime start,
    required DateTime end,
  });

  Future<List<Appointment>> getByClient(String clientId);

  Stream<List<Appointment>> streamByClient(String clientId);

  // ==========================================================
  // 🔹 Buscar por profissional + status
  // ==========================================================
  Future<List<Appointment>> getByProfessionalAndStatus({
    required String professionalId,
    required AppointmentStatus status,
  });

  // ==========================================================
  // 🔹 Buscar por profissional e período (NOVO - FUNDAMENTAL)
  // ==========================================================
  Future<List<Appointment>> getByProfessionalAndPeriod({
    required String professionalId,
    required DateTime start,
    required DateTime end,
  });

  // ==========================================================
  // 🔹 Cancelamento
  // ==========================================================
  Future<void> cancelAppointment({
    required String appointmentId,
  });

  // ==========================================================
  // 🔹 Solicitar reagendamento
  // ==========================================================
  Future<void> requestReschedule({
    required String appointmentId,
    required DateTime proposedStart,
    required DateTime proposedEnd,
    String? message,
  });

  // ==========================================================
  // 🔹 Confirmar reagendamento
  // ==========================================================
  Future<void> confirmReschedule({
    required String appointmentId,
    required DateTime newStart,
    required DateTime newEnd,
  });

  // ==========================================================
  // 🔹 Atualizar anotações
  // ==========================================================
  Future<void> updateAppointmentNotes({
    required String appointmentId,
    String? notes,
  });
}