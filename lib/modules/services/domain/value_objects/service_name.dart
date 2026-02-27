import '../exceptions/service_exception.dart';

class ServiceName {
  final String value;

  ServiceName(String value)
      : value = value.trim() {
    if (this.value.isEmpty) {
      throw ServiceValidationException(
        'Nome do serviço não pode ser vazio',
      );
    }

    if (this.value.length < 3) {
      throw ServiceValidationException(
        'Nome deve ter no mínimo 3 caracteres',
      );
    }
  }

  @override
  String toString() => value;
}