int _counter = 0;

/// Generates a unique, stable ID for a new mock record. A real backend
/// would assign IDs server-side.
String newId(String prefix) {
  _counter++;
  return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_counter';
}
