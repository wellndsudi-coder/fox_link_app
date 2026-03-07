import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/manual_block.dart';

class ManualBlockModel extends ManualBlock {
  ManualBlockModel({
    required super.id,
    required super.tenantId,
    required super.professionalId,
    required super.start,
    required super.end,
    required super.label,
    super.type,
  });

  factory ManualBlockModel.fromEntity(ManualBlock block) {
    return ManualBlockModel(
      id: block.id,
      tenantId: block.tenantId,
      professionalId: block.professionalId,
      start: block.start,
      end: block.end,
      label: block.label,
      type: block.type,
    );
  }

  static String _typeToStorage(ManualBlockType t) {
    return t == ManualBlockType.breakType ? 'break' : t.name;
  }

  static ManualBlockType _typeFromStorage(String? s) {
    if (s == null) return ManualBlockType.custom;
    if (s == 'break') return ManualBlockType.breakType;
    try {
      return ManualBlockType.values.firstWhere(
        (e) => e.name == s,
        orElse: () => ManualBlockType.custom,
      );
    } catch (_) {
      return ManualBlockType.custom;
    }
  }

  factory ManualBlockModel.fromMap(Map<String, dynamic> map, String id) {
    final type = _typeFromStorage(map['type'] as String?);

    return ManualBlockModel(
      id: id,
      tenantId: map['tenantId'] as String,
      professionalId: map['professionalId'] as String,
      start: (map['start'] as Timestamp).toDate(),
      end: (map['end'] as Timestamp).toDate(),
      label: map['label'] as String? ?? '',
      type: type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'professionalId': professionalId,
      'start': start,
      'end': end,
      'label': label,
      'type': _typeToStorage(type),
    };
  }
}
