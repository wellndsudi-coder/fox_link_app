import '../../domain/entities/availability.dart';

class AvailabilityModel extends Availability {
  AvailabilityModel({
    required super.id,
    required super.professionalId,
    required super.weekday,
    required super.isActive,
    required super.shifts,
  });

  factory AvailabilityModel.fromMap(
      Map<String, dynamic> map,
      String id,
      ) {
    return AvailabilityModel(
      id: id,
      professionalId: map['professionalId'] as String,
      weekday: (map['weekday'] as num).toInt(),
      isActive: map['isActive'] as bool? ?? true,
      shifts: (map['shifts'] as List<dynamic>? ?? [])
          .map((e) => TimeRange(
        startMinutes:
        (e['startMinutes'] as num).toInt(),
        endMinutes:
        (e['endMinutes'] as num).toInt(),
      ))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'professionalId': professionalId,
      'weekday': weekday,
      'isActive': isActive,
      'shifts': shifts
          .map((s) => {
        'startMinutes': s.startMinutes,
        'endMinutes': s.endMinutes,
      })
          .toList(),
    };
  }
}