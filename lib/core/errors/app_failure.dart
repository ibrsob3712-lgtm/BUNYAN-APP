class AppFailure implements Exception {
  final String message;
  final Object? cause;
  const AppFailure(this.message, [this.cause]);
  @override
  String toString() => message;
}
