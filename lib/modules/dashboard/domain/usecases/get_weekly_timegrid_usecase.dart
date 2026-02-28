import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/modules/scheduling/domain/repositories/scheduling_repository.dart';

class TimeGridBlock {
  final int weekday; // 1-7
  final int startMinutes;
  final int durationMinutes;

  // 🔥 pronto para UI proporcional
  final double topFactor;
  final double heightFactor;

  TimeGridBlock({
    required this.weekday,
    required this.startMinutes,
    required this.durationMinutes,
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
      if (appointment.status != AppointmentStatus.approved) continue;

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
          weekday: weekday,
          startMinutes: startMinutes,
          durationMinutes: appointment.finalDuration.toInt(),
          topFactor: topFactor.clamp(0, 1),
          heightFactor: heightFactor.clamp(0, 1),
        ),
      );
    }

    return blocks;
  }
}