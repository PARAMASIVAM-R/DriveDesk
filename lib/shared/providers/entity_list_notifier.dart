import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Base for notifiers that hold a list of entities loaded from a repository
/// and keep the in-memory list in sync after each mutation.
abstract class EntityListNotifier<T> extends AsyncNotifier<List<T>> {
  String idOf(T entity);

  /// Current items, waiting for the initial load if needed.
  Future<List<T>> current() => future;

  void upsertAll(Iterable<T> entities) {
    final list = [...?state.value];
    for (final e in entities) {
      final i = list.indexWhere((x) => idOf(x) == idOf(e));
      if (i >= 0) {
        list[i] = e;
      } else {
        list.add(e);
      }
    }
    state = AsyncData(list);
  }

  void removeWhere(bool Function(T) test) {
    state = AsyncData([...?state.value]..removeWhere(test));
  }
}
