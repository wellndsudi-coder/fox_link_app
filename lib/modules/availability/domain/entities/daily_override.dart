import 'availability.dart';

class DailyOverride {
  final String id;
  final String professionalId;
  final DateTime date;

  /// Múltiplos turnos (ex: 08:00-13:00 e 14:00-18:00)
  final List<TimeRange> shifts;

  /// Intervalo entre clientes em minutos
  final int slotIntervalMinutes;

  DailyOverride({
    required this.id,
    required this.professionalId,
    required this.date,
    required this.shifts,
    this.slotIntervalMinutes = 0,
  }) {
    _validate();
  }

  /// Para compatibilidade: primeiro turno (start/end)
  int get startMinutes => shifts.isNotEmpty ? shifts.first.startMinutes : 0;
  int get endMinutes => shifts.isNotEmpty ? shifts.last.endMinutes : 0;

  void _validate() {
    if (shifts.isEmpty) {
      throw Exception("Deve haver ao menos um turno.");
    }
    for (final s in shifts) {
      if (s.startMinutes >= s.endMinutes) {
        throw Exception("Horário inicial deve ser menor que horário final.");
      }
      if (s.startMinutes < 0 || s.endMinutes > 1440) {
        throw Exception("Horário fora do intervalo válido do dia.");
      }
    }
  }
}