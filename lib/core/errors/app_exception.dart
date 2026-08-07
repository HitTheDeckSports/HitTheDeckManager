sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

final class ValidationException extends AppException {
  const ValidationException(super.message, {super.cause});
}

final class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.cause});
}

final class DuplicateException extends AppException {
  const DuplicateException(super.message, {super.cause});
}

final class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause});
}

final class PermissionException extends AppException {
  const PermissionException(super.message, {super.cause});
}

final class UnexpectedException extends AppException {
  const UnexpectedException(super.message, {super.cause});
}
