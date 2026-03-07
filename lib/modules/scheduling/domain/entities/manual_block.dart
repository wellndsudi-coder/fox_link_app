import 'package:equatable/equatable.dart';

enum ManualBlockType {
  lunch,
  meeting,
  breakType,
  custom,
}

class ManualBlock extends Equatable {
  final String id;
  final String tenantId;
  final String professionalId;
  final DateTime start;
  final DateTime end;
  final String label;
  final ManualBlockType type;

  const ManualBlock({
    required this.id,
    required this.tenantId,
    required this.professionalId,
    required this.start,
    required this.end,
    required this.label,
    this.type = ManualBlockType.custom,
  });

  int get durationMinutes =>
      end.difference(start).inMinutes;

  @override
  List<Object?> get props => [id, tenantId, professionalId, start, end, label, type];
}
