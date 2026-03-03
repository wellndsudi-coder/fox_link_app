import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/modules/scheduling/domain/repositories/scheduling_repository.dart';

// 🔥 ALTERAÇÃO 1: Expandimos o bloco para suportar dados completos da agenda
class TimeGridBlock {
  final String appointmentId; // 🔥 NOVO
  final int weekday; // 1-7
  final int startMinutes;
  final int durationMinutes;

  final AppointmentStatus status; // 🔥 NOVO
  final String clientName; // 🔥 NOVO (temporário: usa clientId)
  final String serviceName; // 🔥 NOVO (temporário: usa serviceId)

  // 🔥 pronto para UI proporcional
  final double topFactor;
  final double heightFactor;

  TimeGridBlock({
    required this.appointmentId,
    required this.weekday,
    required this.startMinutes,
    required this.durationMinutes,
    required this.status,
    required this.clientName,
    required this.serviceName,
    required this.topFactor,
    required this.heightFactor,
  });
}

class GetWeeklyTimeGridUseCase {
  final SchedulingRepository repository;

  GetWeeklyTimeGridUseCase(this.repository);

  Future<List<TimeGridBlock>> call({
    required String professionalId,
    required DateTime referenceDate,
  }) async {

    final startOfWeek =
    referenceDate.subtract(Duration(days: referenceDate.weekday - 1));

    final endOfWeek =
    startOfWeek.add(const Duration(days: 7));

    final appointments =
    await repository.getByProfessionalAndPeriod(
      professionalId: professionalId,
      start: startOfWeek,
      end: endOfWeek,
    );

    final List<TimeGridBlock> blocks = [];

    for (final appointment in appointments) {

      // 🔥 ALTERAÇÃO 2: REMOVIDO filtro apenas approved
      // Agora mostramos TODOS os status

      final weekday = appointment.scheduledStart.weekday;

      final startMinutes =
          appointment.scheduledStart.hour * 60 +
              appointment.scheduledStart.minute;

      const gridStart = 7 * 60;  // 07:00
      const gridEnd = 20 * 60;   // 20:00
      const totalMinutes = gridEnd - gridStart;

      final topFactor =
          (startMinutes - gridStart) / totalMinutes;

      final heightFactor =
          appointment.finalDuration.toInt() / totalMinutes;

      blocks.add(
        TimeGridBlock(
          appointmentId: appointment.id, // 🔥 NOVO
          weekday: weekday,
          startMinutes: startMinutes,
          durationMinutes: appointment.finalDuration.toInt(),
          status: appointment.status, // 🔥 NOVO
          clientName: appointment.clientId, // 🔥 TEMPORÁRIO
          serviceName: appointment.serviceId, // 🔥 TEMPORÁRIO
          topFactor: topFactor.clamp(0, 1),
          heightFactor: heightFactor.clamp(0, 1),
        ),
      );
    }

    return blocks;
  }
}