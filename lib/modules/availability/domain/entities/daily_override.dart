class DailyOverride {
  final String id;
  final String professionalId;
  final DateTime date;

  /// Minutes since 00:00
  final int startMinutes;
  final int endMinutes;

  DailyOverride({
    required this.id,
    required this.professionalId,
    required this.date,
    required this.startMinutes,
    required this.endMinutes,
  }) {
    _validate();
  }

  void _validate() {
    if (startMinutes >= endMinutes) {
      throw Exception("Horário inicial deve ser menor que horário final.");
    }

    if (startMinutes < 0 || endMinutes > 1440) {
      throw Exception("Horário fora do intervalo válido do dia.");
    }
  }
}