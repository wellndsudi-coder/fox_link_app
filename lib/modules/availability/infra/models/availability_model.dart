import '../../domain/entities/availability.dart';

class AvailabilityModel extends Availability {
  AvailabilityModel({
    required super.id,
    required super.professionalId,
    required super.weekday,
    required super.isActive,
    required super.shifts,
    required super.slotIntervalMinutes,
    required super.breakTimes,
  });

  factory AvailabilityModel.fromMap(
      Map<String, dynamic> map,
      String id,
      ) {
    // 🔥 Compatibilidade retroativa
    List<TimeRange> parsedBreakTimes = [];

    // Novo formato
    if (map['breakTimes'] != null) {
      parsedBreakTimes =
          (map['breakTimes'] as List<dynamic>)
              .map(
                (e) => TimeRange(
              startMinutes:
              (e['startMinutes'] as num).toInt(),
              endMinutes:
              (e['endMinutes'] as num).toInt(),
            ),
          )
              .toList();
    }
    // Formato antigo
    else if (map['breakTime'] != null) {
      parsedBreakTimes = [
        TimeRange(
          startMinutes:
          (map['breakTime']['startMinutes'] as num)
              .toInt(),
          endMinutes:
          (map['breakTime']['endMinutes'] as num)
              .toInt(),
        )
      ];
    }

    return AvailabilityModel(
      id: id,
      professionalId: map['professionalId'] as String,
      weekday: (map['weekday'] as num).toInt(),
      isActive: map['isActive'] as bool? ?? true,

      slotIntervalMinutes:
      (map['slotIntervalMinutes'] as num?)
          ?.toInt() ??
          0,

      shifts: (map['shifts'] as List<dynamic>? ?? [])
          .map(
            (e) => TimeRange(
          startMinutes:
          (e['startMinutes'] as num).toInt(),
          endMinutes:
          (e['endMinutes'] as num).toInt(),
        ),
      )
          .toList(),

      breakTimes: parsedBreakTimes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'professionalId': professionalId,
      'weekday': weekday,
      'isActive': isActive,
      'slotIntervalMinutes': slotIntervalMinutes,
      'shifts': shifts
          .map(
            (s) => {
          'startMinutes': s.startMinutes,
          'endMinutes': s.endMinutes,
        },
      )
          .toList(),

      // 🔥 Novo padrão oficial
      'breakTimes': breakTimes
          .map(
            (b) => {
          'startMinutes': b.startMinutes,
          'endMinutes': b.endMinutes,
        },
      )
          .toList(),
    };
  }
}