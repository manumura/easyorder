class AlreadyInUseException implements Exception {
  AlreadyInUseException(this.message);

  final String message;
}
