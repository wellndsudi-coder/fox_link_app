/// Horário de um turno (ex: 09:00 - 18:00)
class TimeRangeConfig {
  final String start; // "09:00"
  final String end;   // "18:00"

  const TimeRangeConfig({required this.start, required this.end});

  Map<String, dynamic> toMap() => {'start': start, 'end': end};

  factory TimeRangeConfig.fromMap(Map<String, dynamic> map) {
    return TimeRangeConfig(
      start: map['start'] as String? ?? '09:00',
      end: map['end'] as String? ?? '18:00',
    );
  }
}

/// Horários de funcionamento por dia da semana.
/// Key: 1=Segunda, 2=Terça, ..., 7=Domingo
typedef OpeningHoursMap = Map<int, List<TimeRangeConfig>>;

/// Configuração completa do tenant/salão.
class TenantConfig {
  final String name;
  final String? logoUrl;
  final String? address;
  final String? city;
  final String? phone;
  final String? description;
  final OpeningHoursMap openingHours;

  const TenantConfig({
    required this.name,
    this.logoUrl,
    this.address,
    this.city,
    this.phone,
    this.description,
    this.openingHours = const {},
  });

  static OpeningHoursMap openingHoursFromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return _defaultOpeningHours();
    final result = <int, List<TimeRangeConfig>>{};
    for (var i = 1; i <= 7; i++) {
      final list = map[i.toString()];
      if (list is List) {
        result[i] = list
            .map((e) => e is Map<String, dynamic> ? TimeRangeConfig.fromMap(e) : null)
            .whereType<TimeRangeConfig>()
            .toList();
      }
    }
    return result.isEmpty ? _defaultOpeningHours() : result;
  }

  static Map<String, dynamic> openingHoursToMap(OpeningHoursMap hours) {
    final map = <String, dynamic>{};
    for (final e in hours.entries) {
      if (e.value.isNotEmpty) {
        map[e.key.toString()] = e.value.map((t) => t.toMap()).toList();
      }
    }
    return map;
  }

  static OpeningHoursMap _defaultOpeningHours() {
    return {
      for (var i = 1; i <= 5; i++) i: [const TimeRangeConfig(start: '09:00', end: '18:00')],
      6: [const TimeRangeConfig(start: '09:00', end: '13:00')], // Sábado
      // 7 Domingo: fechado (lista vazia)
    };
  }

  bool isOpenOnWeekday(int weekday) {
    final ranges = openingHours[weekday];
    return ranges != null && ranges.isNotEmpty;
  }

  /// Retorna os intervalos de abertura em minutos (0-1440) para o dia.
  List<({int start, int end})> getOpeningRangesMinutes(int weekday) {
    final ranges = openingHours[weekday];
    if (ranges == null || ranges.isEmpty) return [];
    return ranges.map((r) {
      final startParts = r.start.split(':');
      final endParts = r.end.split(':');
      final start = int.parse(startParts[0]) * 60 + int.parse(startParts.length > 1 ? startParts[1] : '0');
      final end = int.parse(endParts[0]) * 60 + int.parse(endParts.length > 1 ? endParts[1] : '0');
      return (start: start, end: end);
    }).toList();
  }

  bool isWithinOpeningHours(int weekday, int startMinutes, int endMinutes) {
    final ranges = getOpeningRangesMinutes(weekday);
    if (ranges.isEmpty) return false;
    for (final r in ranges) {
      if (startMinutes >= r.start && endMinutes <= r.end) return true;
    }
    return false;
  }
}
