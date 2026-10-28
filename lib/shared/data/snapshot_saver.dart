import 'dart:async';

import 'local_store.dart';
import 'mock_database.dart';

/// Persists [MockDatabase] snapshots to a [LocalStore]. Every
/// [MockDatabase.markDirty] schedules a save after [debounce], so a burst of
/// writes results in a single file write. Call [flush] to save immediately
/// (e.g. when the app is backgrounded).
class SnapshotSaver {
  SnapshotSaver(
    this._db,
    this._store, {
    this.debounce = const Duration(milliseconds: 300),
  }) {
    _db.addListener(_onDirty);
  }

  final MockDatabase _db;
  final LocalStore _store;
  final Duration debounce;

  Timer? _timer;
  bool _dirty = false;
  Future<void> _pending = Future.value();

  bool get hasPendingChanges => _dirty;

  void _onDirty() {
    _dirty = true;
    _timer?.cancel();
    _timer = Timer(debounce, flush);
  }

  /// Writes the current snapshot now if there are unsaved changes, and
  /// completes once every write started so far has finished.
  Future<void> flush() {
    _timer?.cancel();
    _timer = null;
    if (_dirty) {
      _dirty = false;
      final json = _db.encode();
      _pending = _pending.then((_) => _store.write(json)).catchError((_) {
        // Storage errors must never crash the app; the next change
        // retries the save.
        _dirty = true;
      });
    }
    return _pending;
  }

  /// Drops unsaved changes and waits for in-flight writes, so a following
  /// [LocalStore.clear] cannot be overwritten by a late save.
  Future<void> discardPending() {
    _timer?.cancel();
    _timer = null;
    _dirty = false;
    return _pending;
  }

  /// Stops listening; any unsaved changes are written best-effort.
  void dispose() {
    if (_dirty) flush();
    _timer?.cancel();
    _db.removeListener(_onDirty);
  }
}
