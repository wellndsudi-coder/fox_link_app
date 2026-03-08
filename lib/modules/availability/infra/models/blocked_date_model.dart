import 'package:cloud_firestore/cloud_firestore.dart';

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
    final dateRaw = map['date'];
    final DateTime date = dateRaw is Timestamp
        ? dateRaw.toDate()
        : dateRaw as DateTime;
    return BlockedDateModel(
      id: id,
      professionalId: map['professionalId'] as String,
      date: date,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'professionalId': professionalId,
      'date': date,
    };
  }
}