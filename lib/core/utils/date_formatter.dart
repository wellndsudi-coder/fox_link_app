import 'package:intl/intl.dart';

/// Centralizado: formatação de datas amigável ao usuário.
class AppDateFormatter {
  AppDateFormatter._();

  static const _locale = 'pt_BR';

  static final _timeFormat = DateFormat('HH:mm', _locale);
  static final _weekdayFormat = DateFormat('EEE', _locale);
  static final _dayMonthFormat = DateFormat('d MMM', _locale);

  /// Data amigável: "Domingo • 8 Mar" ou "Hoje" / "Amanhã"
  static String friendlyDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) return 'Hoje';
    if (target == today.add(const Duration(days: 1))) return 'Amanhã';
    if (target == today.subtract(const Duration(days: 1))) return 'Ontem';

    return '${_weekdayFormat.format(date)} • ${_dayMonthFormat.format(date)}';
  }

  /// Horário: "15:04"
  static String friendlyTime(DateTime dateTime) {
    return _timeFormat.format(dateTime);
  }

  /// Data + horário: "Hoje • 15:04" ou "Amanhã • 09:30" ou "Domingo • 8 Mar • 15:04"
  static String friendlyDateAndTime(DateTime dateTime) {
    return '${friendlyDate(dateTime)} • ${friendlyTime(dateTime)}';
  }

  /// Duração em minutos para string: "30 min"
  static String friendlyDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }
}
