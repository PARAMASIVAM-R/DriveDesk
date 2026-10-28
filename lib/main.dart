import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'features/auth/presentation/session_provider.dart';
import 'shared/data/local_store.dart';
import 'shared/data/mock_database.dart';
import 'shared/providers/core_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dataStore = FileLocalStore('drivedesk_data.json');
  final sessionStore = FileLocalStore('drivedesk_session.json');

  // A missing, corrupted or outdated snapshot falls back to seed data.
  MockDatabase? restored;
  try {
    restored = MockDatabase.tryDecode(await dataStore.read());
  } catch (_) {
    restored = null;
  }
  final db = restored ?? MockDatabase.seeded(DateTime.now());
  // Bring older snapshots up to date with newly added sample records,
  // without touching anything the user changed.
  if (db.seedVersion < MockDatabase.currentSeedVersion) {
    db.addMissingSeedData(MockDatabase.seeded(DateTime.now()));
    await dataStore.write(db.encode());
  }
  final session = await loadStoredSession(sessionStore);

  runApp(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(dataStore),
        sessionStoreProvider.overrideWithValue(sessionStore),
        mockDatabaseProvider.overrideWithValue(db),
        initialSessionProvider.overrideWithValue(session),
      ],
      child: const _PersistenceScope(child: DriveDeskApp()),
    ),
  );
}

/// Flushes unsaved data when the app is paused, hidden or closed so nothing
/// is lost if the OS kills it in the background.
class _PersistenceScope extends ConsumerStatefulWidget {
  const _PersistenceScope({required this.child});

  final Widget child;

  @override
  ConsumerState<_PersistenceScope> createState() => _PersistenceScopeState();
}

class _PersistenceScopeState extends ConsumerState<_PersistenceScope> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    void flush() => ref.read(snapshotSaverProvider).flush();
    _lifecycle = AppLifecycleListener(
      onPause: flush,
      onHide: flush,
      onDetach: flush,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
