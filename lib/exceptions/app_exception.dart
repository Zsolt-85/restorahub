class AppException implements Exception {
  final String message;
  final String? code;
  final Object? cause;

  const AppException(this.message, {this.code, this.cause});

  @override
  String toString() => 'AppException: $message${code != null ? ' ($code)' : ''}';
}

class AuthException extends AppException {
  const AuthException(String message, {String? code, Object? cause})
      : super(message, code: code, cause: cause);
}

class NetworkException extends AppException {
  const NetworkException(String message, {String? code, Object? cause})
      : super(message, code: code, cause: cause);
}

class BookingException extends AppException {
  const BookingException(String message, {String? code, Object? cause})
      : super(message, code: code, cause: cause);
}

class PermissionException extends AppException {
  const PermissionException(String message, {String? code, Object? cause})
      : super(message, code: code, cause: cause);
}
