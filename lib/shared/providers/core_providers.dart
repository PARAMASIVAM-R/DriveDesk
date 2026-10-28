import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_store.dart';
import '../data/mock_database.dart';
import '../data/snapshot_saver.dart';

/// Current time source. Override in tests for deterministic dates.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Where the [MockDatabase] snapshot is persisted. Defaults to a volatile
/// in-memory store; `main.dart` overrides it with a file-backed store.
final localStoreProvider = Provider<LocalStore>((ref) => InMemoryLocalStore());

/// Where the signed-in demo session is persisted. Same defaults as
/// [localStoreProvider].
final sessionStoreProvider = Provider<LocalStore>(
  (ref) => InMemoryLocalStore(),
);

/// In-memory store backing every mock repository. `main.dart` overrides it
/// with the snapshot loaded from [localStoreProvider] when one exists.
/// Swap the repository providers (not this) for API-backed versions later.
final mockDatabaseProvider = Provider<MockDatabase>(
  (ref) => MockDatabase.seeded(ref.watch(clockProvider)()),
);

/// Debounced saver writing [mockDatabaseProvider] to [localStoreProvider]
/// whenever a repository marks the database dirty.
final snapshotSaverProvider = Provider<SnapshotSaver>((ref) {
  final saver = SnapshotSaver(
    ref.watch(mockDatabaseProvider),
    ref.watch(localStoreProvider),
  );
  ref.onDispose(saver.dispose);
  return saver;
});

/// The database for repository providers. Also keeps [snapshotSaverProvider]
/// alive, so every write made through a repository gets persisted.
MockDatabase watchPersistedDatabase(Ref ref) {
  ref.watch(snapshotSaverProvider);
  return ref.watch(mockDatabaseProvider);
}

/// The school the app is operating on. Centralised so a future backend can
/// enforce tenant boundaries from a single place.
const demoSchoolId = 'sch_001';
