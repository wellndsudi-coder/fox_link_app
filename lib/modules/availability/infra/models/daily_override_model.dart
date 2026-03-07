import '../../domain/entities/availability.dart';
import '../../domain/entities/daily_override.dart';

class DailyOverrideModel extends DailyOverride {
  DailyOverrideModel({
    required super.id,
    required super.professionalId,
    required super.date,
    required super.shifts,
    super.slotIntervalMinutes = 0,
  });

  factory DailyOverrideModel.fromMap(Map<String, dynamic> map, String id) {
    List<TimeRange> shifts;
    if (map['shifts'] != null && (map['shifts'] as List).isNotEmpty) {
      shifts = (map['shifts'] as List)
          .map((e) => TimeRange(
                startMinutes: (e['startMinutes'] as num).toInt(),
                endMinutes: (e['endMinutes'] as num).toInt(),
              ))
          .toList();
    } else {
      // Retrocompatibilidade: startMinutes/endMinutes
      shifts = [
        TimeRange(
          startMinutes: (map['startMinutes'] as num?)?.toInt() ?? 0,
          endMinutes: (map['endMinutes'] as num?)?.toInt() ?? 0,
        ),
      ];
    }
    return DailyOverrideModel(
      id: id,
      professionalId: map['professionalId'] as String,
      date: map['date'] as DateTime,
      shifts: shifts,
      slotIntervalMinutes: (map['slotIntervalMinutes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'professionalId': professionalId,
      'date': date,
      'shifts': shifts
          .map((s) => {
                'startMinutes': s.startMinutes,
                'endMinutes': s.endMinutes,
              })
          .toList(),
      'slotIntervalMinutes': slotIntervalMinutes,
    };
  }
}