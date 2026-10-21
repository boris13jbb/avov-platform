class AppException implements Exception {
  AppException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException(super.message, {super.statusCode});
}

class UnauthorizedException extends AppException {
  UnauthorizedException([super.message = 'Sesión expirada o no autorizada'])
      : super(statusCode: 401);
}

class ValidationException extends AppException {
  ValidationException(
    super.message, {
    this.fieldErrors = const [],
  }) : super(statusCode: 422);

  final List<String> fieldErrors;
}
