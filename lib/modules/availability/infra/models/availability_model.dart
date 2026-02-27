import '../../domain/entities/availability.dart';

class AvailabilityModel extends Availability {
  AvailabilityModel({
    required super.id,
    required super.professionalId,
    required super.weekday,
    required super.startMinutes,
    required super.endMinutes,
    super.breakStartMinutes,
    super.breakEndMinutes,
  });

  factory AvailabilityModel.fromMap(
      Map<String, dynamic> map,
      String id,
      ) {
    return AvailabilityModel(
      id: id,
      professionalId: map['professionalId'] as String,
      weekday: (map['weekday'] as num).toInt(),
      startMinutes: (map['startMinutes'] as num).toInt(),
      endMinutes: (map['endMinutes'] as num).toInt(),
      breakStartMinutes:
      map['breakStartMinutes'] != null
          ? (map['breakStartMinutes'] as num).toInt()
          : null,
      breakEndMinutes:
      map['breakEndMinutes'] != null
          ? (map['breakEndMinutes'] as num).toInt()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'professionalId': professionalId,
      'weekday': weekday,
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
      'breakStartMinutes': breakStartMinutes,
      'breakEndMinutes': breakEndMinutes,
    };
  }
}