import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';
import '../domain/session.dart';

final sessionProvider = NotifierProvider<SessionNotifier, DemoSession?>(
  SessionNotifier.new,
);

/// Holds the simulated signed-in user. No credentials are checked.
class SessionNotifier extends Notifier<DemoSession?> {
  @override
  DemoSession? build() => null;

  void signIn({
    required UserRole role,
    required String userId,
    required String displayName,
  }) {
    state = DemoSession(
      role: role,
      userId: userId,
      displayName: displayName,
      schoolId: demoSchoolId,
    );
  }

  void signOut() => state = null;
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
