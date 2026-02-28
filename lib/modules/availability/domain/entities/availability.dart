class Availability {
  final String id;
  final String professionalId;

  /// 1 = Monday ... 7 = Sunday
  final int weekday;

  /// Se o dia está ativo
  final bool isActive;

  /// Lista de turnos no dia
  final List<TimeRange> shifts;

  Availability({
    required this.id,
    required this.professionalId,
    required this.weekday,
    required this.isActive,
    required this.shifts,
  }) {
    _validate();
  }

  void _validate() {
    if (weekday < 1 || weekday > 7) {
      throw Exception("Weekday inválido.");
    }

    if (!isActive) return;

    if (shifts.isEmpty) {
      throw Exception("Dia ativo deve possuir ao menos um turno.");
    }

    for (final shift in shifts) {
      if (shift.startMinutes >= shift.endMinutes) {
        throw Exception("Turno inválido.");
      }

      if (shift.startMinutes < 0 || shift.endMinutes > 1440) {
        throw Exception("Turno fora do intervalo válido.");
      }
    }

    for (int i = 0; i < shifts.length; i++) {
      for (int j = i + 1; j < shifts.length; j++) {
        if (_isOverlapping(shifts[i], shifts[j])) {
          throw Exception("Turnos não podem se sobrepor.");
        }
      }
    }
  }

  bool _isOverlapping(TimeRange a, TimeRange b) {
    return a.startMinutes < b.endMinutes &&
        a.endMinutes > b.startMinutes;
  }
}

class TimeRange {
  final int startMinutes;
  final int endMinutes;

  TimeRange({
    required this.startMinutes,
    required this.endMinutes,
  });
}