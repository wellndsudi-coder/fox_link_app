class ServiceException implements Exception {
  final String message;

  ServiceException(this.message);

  @override
  String toString() => message;
}

class ServiceValidationException extends ServiceException {
  ServiceValidationException(String message) : super(message);
}