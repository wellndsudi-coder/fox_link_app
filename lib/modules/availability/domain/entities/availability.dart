class Availability {
  final String id;
  final String professionalId;

  /// 1 = Monday ... 7 = Sunday
  final int weekday;

  /// Minutes since 00:00
  final int startMinutes;
  final int endMinutes;

  /// Optional break interval
  final int? breakStartMinutes;
  final int? breakEndMinutes;

  Availability({
    required this.id,
    required this.professionalId,
    required this.weekday,
    required this.startMinutes,
    required this.endMinutes,
    this.breakStartMinutes,
    this.breakEndMinutes,
  }) {
    _validate();
  }

  void _validate() {
    if (weekday < 1 || weekday > 7) {
      throw Exception("Weekday inválido. Deve ser entre 1 e 7.");
    }

    if (startMinutes >= endMinutes) {
      throw Exception("Horário inicial deve ser menor que horário final.");
    }

    if (startMinutes < 0 || endMinutes > 1440) {
      throw Exception("Horário fora do intervalo válido do dia.");
    }

    if ((breakStartMinutes == null) != (breakEndMinutes == null)) {
      throw Exception("Intervalo de pausa inválido.");
    }

    if (breakStartMinutes != null && breakEndMinutes != null) {
      if (breakStartMinutes! >= breakEndMinutes!) {
        throw Exception("Intervalo de pausa inválido.");
      }

      if (breakStartMinutes! <= startMinutes ||
          breakEndMinutes! >= endMinutes) {
        throw Exception("Pausa deve estar dentro do horário principal.");
      }
    }
  }
}