class AuthenticationException implements Exception {
  AuthenticationException(this.message, this.cause);

  final String message;

  final Exception cause;
}
