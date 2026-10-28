import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Minimal key-less storage for a single text document (e.g. a JSON
/// snapshot). Implementations must be safe to call concurrently from a
/// single isolate.
abstract interface class LocalStore {
  /// Returns the stored text, or null if nothing has been written.
  Future<String?> read();

  Future<void> write(String data);

  Future<void> clear();
}

/// Volatile store used by default (and in tests). Nothing survives a
/// restart.
class InMemoryLocalStore implements LocalStore {
  InMemoryLocalStore([this.data]);

  String? data;

  /// Number of completed [write] calls, handy for tests.
  int writeCount = 0;

  @override
  Future<String?> read() async => data;

  @override
  Future<void> write(String data) async {
    this.data = data;
    writeCount++;
  }

  @override
  Future<void> clear() async => data = null;
}

/// Stores the document as [fileName] in the app documents directory.
/// Writes go to a temporary file which is then renamed over the target, so
/// a crash mid-write never leaves a truncated file behind.
class FileLocalStore implements LocalStore {
  FileLocalStore(this.fileName, {Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationDocumentsDirectory;

  final String fileName;
  final Future<Directory> Function() _directory;

  /// Serialises operations so a slow write cannot land after a later
  /// write or clear.
  Future<void> _queue = Future.value();

  Future<File> _file() async =>
      File('${(await _directory()).path}${Platform.pathSeparator}$fileName');

  Future<T> _enqueue<T>(Future<T> Function() op) {
    final result = _queue.then((_) => op());
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  @override
  Future<String?> read() => _enqueue(() async {
    final file = await _file();
    if (!await file.exists()) return null;
    return file.readAsString();
  });

  @override
  Future<void> write(String data) => _enqueue(() async {
    final file = await _file();
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(data, flush: true);
    await tmp.rename(file.path);
  });

  @override
  Future<void> clear() => _enqueue(() async {
    final file = await _file();
    if (await file.exists()) await file.delete();
  });
}
