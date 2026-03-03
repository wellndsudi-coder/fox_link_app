class Availability {
  final String id;
  final String professionalId;

  /// 1 = Monday ... 7 = Sunday
  final int weekday;

  /// Se o dia está ativo
  final bool isActive;

  /// Lista de turnos no dia
  final List<TimeRange> shifts;

  /// 🔥 Intervalo entre clientes (ex: 15, 30, 60)
  final int slotIntervalMinutes;

  /// 🔥 NOVO — múltiplos intervalos de refeição
  final List<TimeRange> breakTimes;

  Availability({
    required this.id,
    required this.professionalId,
    required this.weekday,
    required this.isActive,
    required this.shifts,
    required this.slotIntervalMinutes,
    List<TimeRange>? breakTimes,
  }) : breakTimes = breakTimes ?? [] {
    _validate();
  }

  void _validate() {
    if (weekday < 1 || weekday > 7) {
      throw Exception("Weekday inválido.");
    }

    if (slotIntervalMinutes < 0 || slotIntervalMinutes > 600) {
      throw Exception("Intervalo entre clientes inválido.");
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

    // 🔥 valida sobreposição entre turnos
    for (int i = 0; i < shifts.length; i++) {
      for (int j = i + 1; j < shifts.length; j++) {
        if (_isOverlapping(shifts[i], shifts[j])) {
          throw Exception("Turnos não podem se sobrepor.");
        }
      }
    }

    // 🔥 valida múltiplos intervalos de refeição
    for (final breakTime in breakTimes) {
      if (breakTime.startMinutes >= breakTime.endMinutes) {
        throw Exception("Intervalo de refeição inválido.");
      }

      if (breakTime.startMinutes < 0 ||
          breakTime.endMinutes > 1440) {
        throw Exception("Intervalo fora do horário válido.");
      }

      bool insideAnyShift = false;

      for (final shift in shifts) {
        if (breakTime.startMinutes >= shift.startMinutes &&
            breakTime.endMinutes <= shift.endMinutes) {
          insideAnyShift = true;
        }
      }

      if (!insideAnyShift) {
        throw Exception(
            "Intervalo de refeição deve estar dentro de um turno.");
      }
    }

    // 🔥 impede sobreposição entre intervalos de refeição
    for (int i = 0; i < breakTimes.length; i++) {
      for (int j = i + 1; j < breakTimes.length; j++) {
        if (_isOverlapping(breakTimes[i], breakTimes[j])) {
          throw Exception(
              "Intervalos de refeição não podem se sobrepor.");
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