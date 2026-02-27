import '../../domain/entities/blocked_date.dart';

class BlockedDateModel extends BlockedDate {
  BlockedDateModel({
    required super.id,
    required super.professionalId,
    required super.date,
  });

  factory BlockedDateModel.fromMap(
      Map<String, dynamic> map,
      String id,
      ) {
    return BlockedDateModel(
      id: id,
      professionalId: map['professionalId'] as String,
      date: map['date'] as DateTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'professionalId': professionalId,
      'date': date,
    };
  }
}