import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';
import '../../fees/presentation/fee_providers.dart';
import '../../licences_tests/presentation/licence_providers.dart';
import '../../scheduling/presentation/lesson_providers.dart';
import '../../settings/presentation/school_providers.dart';
import '../../students/presentation/student_providers.dart';
import '../data/mock_reminder_repository.dart';
import '../domain/reminder.dart';
import '../domain/reminder_generator.dart';

final reminderStatusesProvider =
    AsyncNotifierProvider<
      ReminderStatusesNotifier,
      Map<String, ReminderStatus>
    >(ReminderStatusesNotifier.new);

class ReminderStatusesNotifier
    extends AsyncNotifier<Map<String, ReminderStatus>> {
  @override
  Future<Map<String, ReminderStatus>> build() =>
      ref.watch(reminderRepositoryProvider).fetchStatuses();

  Future<void> setStatus(String reminderId, ReminderStatus status) async {
    await ref.read(reminderRepositoryProvider).setStatus(reminderId, status);
    state = AsyncData({...?state.value, reminderId: status});
  }
}

/// Reminders derived from current records, with any recorded demo status.
final remindersProvider = Provider<List<Reminder>>((ref) {
  final statuses = ref.watch(reminderStatusesProvider).value ?? const {};
  final generated = ReminderGenerator.generate(
    schoolName: ref.watch(schoolProvider).value?.name ?? 'Your driving school',
    students: ref.watch(studentsProvider).value ?? const [],
    lessons: ref.watch(lessonsProvider).value ?? const [],
    licences: ref.watch(licencesProvider).value ?? const [],
    tests: ref.watch(testsProvider).value ?? const [],
    fees: ref.watch(feeSummariesProvider),
    now: ref.watch(clockProvider)(),
  );
  return [
    for (final r in generated)
      statuses.containsKey(r.id) ? r.withStatus(statuses[r.id]!) : r,
  ];
});

final remindersForStudentProvider = Provider.family<List<Reminder>, String>(
  (ref, studentId) => ref
      .watch(remindersProvider)
      .where((r) => r.studentId == studentId)
      .toList(),
);
