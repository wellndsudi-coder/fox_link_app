import '../exceptions/service_exception.dart';

class ServiceDuration {
  final int minutes;

  ServiceDuration(int minutes) : minutes = minutes {
    if (minutes < 5) {
      throw ServiceValidationException(
        'Duração mínima é 5 minutos',
      );
    }

    if (minutes > 600) {
      throw ServiceValidationException(
        'Duração máxima é 10 horas',
      );
    }
  }

  Duration toDuration() => Duration(minutes: minutes);

  @override
  String toString() => '$minutes minutos';
}