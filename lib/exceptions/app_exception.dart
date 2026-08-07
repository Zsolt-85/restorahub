class AppException implements Exception {
  final String message;
  final String? code;
  final Object? originalException;

  const AppException(this.message, {this.code, this.originalException});

  @override
  String toString() => 'AppException: $message${code != null ? ' ($code)' : ''}';
}

class AuthException extends AppException {
  const AuthException(String message, {String? code, Object? originalException})
      : super(message, code: code, originalException: originalException);
}

class NetworkException extends AppException {
  const NetworkException(String message, {String? code, Object? originalException})
      : super(message, code: code, originalException: originalException);
}

class BookingException extends AppException {
  const BookingException(String message, {String? code, Object? originalException})
      : super(message, code: code, originalException: originalException);
}

class PermissionException extends AppException {
  const PermissionException(String message, {String? code, Object? originalException})
      : super(message, code: code, originalException: originalException);
}
