import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/modules/scheduling/domain/repositories/scheduling_repository.dart';

class TimeGridBlock {
  final String appointmentId;
  final int weekday;
  final int startMinutes;
  final int durationMinutes;

  final AppointmentStatus status;

  // 🔥 Agora são labels, não IDs
  final String clientLabel;
  final String serviceLabel;

  final double topFactor;
  final double heightFactor;

  TimeGridBlock({
    required this.appointmentId,
    required this.weekday,
    required this.startMinutes,
    required this.durationMinutes,
    required this.status,
    required this.clientLabel,
    required this.serviceLabel,
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

      final weekday = appointment.scheduledStart.weekday;

      final startMinutes =
          appointment.scheduledStart.hour * 60 +
              appointment.scheduledStart.minute;

      const gridStart = 7 * 60;
      const gridEnd = 20 * 60;
      const totalMinutes = gridEnd - gridStart;

      final topFactor =
          (startMinutes - gridStart) / totalMinutes;

      final heightFactor =
          appointment.finalDuration / totalMinutes;

      blocks.add(
        TimeGridBlock(
          appointmentId: appointment.id,
          weekday: weekday,
          startMinutes: startMinutes,
          durationMinutes: appointment.finalDuration,
          status: appointment.status,

          // 🔥 Visual temporário melhorado
          clientLabel: "Cliente",
          serviceLabel: "Serviço",

          topFactor: topFactor.clamp(0, 1),
          heightFactor: heightFactor.clamp(0, 1),
        ),
      );
    }

    return blocks;
  }
}