import '../exceptions/service_exception.dart';

class Money {
  final double value;

  Money(double value) : value = value {
    if (value < 0) {
      throw ServiceValidationException(
        'Preço não pode ser negativo',
      );
    }
  }

  Money operator +(Money other) => Money(value + other.value);

  @override
  String toString() => value.toStringAsFixed(2);
}