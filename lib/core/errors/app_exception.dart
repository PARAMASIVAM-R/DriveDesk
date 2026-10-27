/// A business-rule violation that should be shown to the user verbatim.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}
