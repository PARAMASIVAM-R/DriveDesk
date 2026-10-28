import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/local_store.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/session.dart';

/// Session restored from [sessionStoreProvider] at startup (see `main.dart`).
/// Null means the app starts on the sign-in screen.
final initialSessionProvider = Provider<DemoSession?>((ref) => null);

/// Reads a session previously saved by [SessionNotifier]; returns null when
/// none is stored or it cannot be parsed.
Future<DemoSession?> loadStoredSession(LocalStore store) async {
  try {
    final raw = await store.read();
    if (raw == null || raw.isEmpty) return null;
    final json = jsonDecode(raw);
    if (json is! Map) return null;
    return DemoSession.fromJson(json.cast<String, Object?>());
  } catch (_) {
    return null;
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, DemoSession?>(
  SessionNotifier.new,
);

/// Holds the simulated signed-in user. No credentials are checked. The
/// session is persisted so reopening the app keeps the user signed in.
class SessionNotifier extends Notifier<DemoSession?> {
  @override
  DemoSession? build() => ref.read(initialSessionProvider);

  void signIn({
    required UserRole role,
    required String userId,
    required String displayName,
  }) {
    final session = DemoSession(
      role: role,
      userId: userId,
      displayName: displayName,
      schoolId: demoSchoolId,
    );
    state = session;
    unawaited(
      ref
          .read(sessionStoreProvider)
          .write(jsonEncode(session.toJson()))
          .catchError((_) {}),
    );
  }

  void signOut() {
    state = null;
    unawaited(ref.read(sessionStoreProvider).clear().catchError((_) {}));
  }
}

/// Role of the current user; throws if called while signed out, which the
/// router prevents.
final currentRoleProvider = Provider<UserRole>(
  (ref) => ref.watch(sessionProvider)?.role ?? UserRole.student,
);

/// The signed-in student's stable ID, or null for staff. Every student
/// portal query is scoped by this value.
final currentStudentIdProvider = Provider<String?>((ref) {
  final session = ref.watch(sessionProvider);
  return session?.role == UserRole.student ? session!.userId : null;
});
