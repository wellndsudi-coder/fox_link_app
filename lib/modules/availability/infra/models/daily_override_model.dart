import '../../domain/entities/daily_override.dart';

class DailyOverrideModel extends DailyOverride {
  DailyOverrideModel({
    required super.id,
    required super.professionalId,
    required super.date,
    required super.startMinutes,
    required super.endMinutes,
  });

  factory DailyOverrideModel.fromMap(
      Map<String, dynamic> map,
      String id,
      ) {
    return DailyOverrideModel(
      id: id,
      professionalId: map['professionalId'] as String,
      date: (map['date'] as DateTime),
      startMinutes: (map['startMinutes'] as num).toInt(),
      endMinutes: (map['endMinutes'] as num).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'professionalId': professionalId,
      'date': date,
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
    };
  }
}