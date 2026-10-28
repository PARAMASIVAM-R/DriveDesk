import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/mock_database.dart';
import '../../../shared/providers/core_providers.dart';
import '../../fees/presentation/fee_providers.dart';
import '../../licences_tests/presentation/licence_providers.dart';
import '../../reminders/presentation/reminder_providers.dart';
import '../../scheduling/presentation/lesson_providers.dart';
import '../../students/presentation/student_providers.dart';
import 'school_providers.dart';

/// Wipes persisted demo data and restores fresh seed data in memory.
/// Usage: `await ref.read(resetDemoDataProvider)()`. The signed-in session
/// is kept (seed IDs are stable).
final resetDemoDataProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => resetDemoData(ref),
);

Future<void> resetDemoData(Ref ref) async {
  await ref.read(snapshotSaverProvider).discardPending();
  await ref.read(localStoreProvider).clear();
  ref
      .read(mockDatabaseProvider)
      .replaceWith(MockDatabase.seeded(ref.read(clockProvider)()));

  // Reload every list so the UI reflects the restored data.
  ref
    ..invalidate(studentsProvider)
    ..invalidate(packagesProvider)
    ..invalidate(lessonsProvider)
    ..invalidate(rescheduleRequestsProvider)
    ..invalidate(paymentsProvider)
    ..invalidate(installmentsProvider)
    ..invalidate(licencesProvider)
    ..invalidate(testsProvider)
    ..invalidate(reminderStatusesProvider)
    ..invalidate(schoolProvider)
    ..invalidate(staffProvider)
    ..invalidate(vehiclesProvider);
}
