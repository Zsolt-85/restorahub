class AppException implements Exception {
  final String message;
  final String? code;
  final Object? cause;

  const AppException(this.message, {this.code, this.cause});

  @override
  String toString() => 'AppException: $message${code != null ? ' ($code)' : ''}';
}
