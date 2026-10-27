import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/ids.dart';
import '../../../shared/providers/core_providers.dart';
import '../../../shared/providers/entity_list_notifier.dart';
import '../data/mock_licence_repository.dart';
import '../domain/licence.dart';

final licencesProvider =
    AsyncNotifierProvider<LicencesNotifier, List<LicenceRecord>>(
      LicencesNotifier.new,
    );

class LicencesNotifier extends EntityListNotifier<LicenceRecord> {
  @override
  String idOf(LicenceRecord entity) => entity.id;

  @override
  Future<List<LicenceRecord>> build() =>
      ref.watch(licenceRepositoryProvider).fetchLicences();

  Future<void> save({
    required String studentId,
    String? existingId,
    String? llrNumber,
    DateTime? issueDate,
    DateTime? expiryDate,
  }) async {
    if (issueDate != null &&
        expiryDate != null &&
        !expiryDate.isAfter(issueDate)) {
      throw const AppException('Expiry date must be after the issue date.');
    }
    final record = LicenceRecord(
      id: existingId ?? newId('llr'),
      schoolId: demoSchoolId,
      studentId: studentId,
      llrNumber: (llrNumber == null || llrNumber.trim().isEmpty)
          ? null
          : llrNumber.trim(),
      issueDate: issueDate,
      expiryDate: expiryDate,
    );
    upsertAll([await ref.read(licenceRepositoryProvider).saveLicence(record)]);
  }
}

/// Latest LLR record for a student, if any.
final licenceForStudentProvider = Provider.family<LicenceRecord?, String>((
  ref,
  studentId,
) {
  final all = ref.watch(licencesProvider).value ?? const [];
  return all.where((l) => l.studentId == studentId).lastOrNull;
});

final testsProvider = AsyncNotifierProvider<TestsNotifier, List<DrivingTest>>(
  TestsNotifier.new,
);

class TestsNotifier extends EntityListNotifier<DrivingTest> {
  @override
  String idOf(DrivingTest entity) => entity.id;

  @override
  Future<List<DrivingTest>> build() =>
      ref.watch(licenceRepositoryProvider).fetchTests();

  Future<void> _persist(List<DrivingTest> tests) async {
    await ref.read(licenceRepositoryProvider).saveTests(tests);
    upsertAll(tests);
  }

  /// Books a new test attempt. Any open "not scheduled" placeholder is
  /// replaced; an already-scheduled test must be rescheduled instead.
  Future<void> book({
    required String studentId,
    required DateTime at,
    required String location,
  }) async {
    final mine = (await current()).where((t) => t.studentId == studentId);
    if (mine.any((t) => t.status == TestStatus.scheduled)) {
      throw const AppException(
        'This student already has a scheduled test. Reschedule it instead.',
      );
    }
    if (mine.any((t) => t.status == TestStatus.passed)) {
      throw const AppException('This student has already passed the test.');
    }
    final placeholder = mine
        .where((t) => t.status == TestStatus.notScheduled)
        .firstOrNull;
    if (placeholder != null) {
      await _persist([
        placeholder.copyWith(
          status: TestStatus.scheduled,
          scheduledAt: at,
          location: location,
        ),
      ]);
      return;
    }
    await _persist([
      DrivingTest(
        id: newId('tst'),
        schoolId: demoSchoolId,
        studentId: studentId,
        attempt: mine.length + 1,
        status: TestStatus.scheduled,
        scheduledAt: at,
        location: location,
      ),
    ]);
  }

  /// Marks the current booking as rescheduled (kept for history) and books
  /// the new slot as a separate record.
  Future<void> reschedule(
    DrivingTest test, {
    required DateTime at,
    required String location,
  }) async {
    if (test.status != TestStatus.scheduled) {
      throw const AppException('Only a scheduled test can be rescheduled.');
    }
    final count = (await current())
        .where((t) => t.studentId == test.studentId)
        .length;
    await _persist([
      test.copyWith(status: TestStatus.rescheduled),
      DrivingTest(
        id: newId('tst'),
        schoolId: test.schoolId,
        studentId: test.studentId,
        attempt: count + 1,
        status: TestStatus.scheduled,
        scheduledAt: at,
        location: location,
      ),
    ]);
  }

  Future<void> recordOutcome(
    DrivingTest test, {
    required bool passed,
    String notes = '',
  }) async {
    if (test.status != TestStatus.scheduled) {
      throw const AppException('Only a scheduled test can have an outcome.');
    }
    final at = test.scheduledAt;
    if (at != null && at.isAfter(ref.read(clockProvider)())) {
      throw const AppException('This test has not taken place yet.');
    }
    await _persist([
      test.copyWith(
        status: passed ? TestStatus.passed : TestStatus.failed,
        notes: notes,
      ),
    ]);
  }
}

/// All test records for a student, oldest attempt first.
final testsForStudentProvider = Provider.family<List<DrivingTest>, String>((
  ref,
  studentId,
) {
  final all = ref.watch(testsProvider).value ?? const [];
  return all.where((t) => t.studentId == studentId).toList()
    ..sort((a, b) => a.attempt.compareTo(b.attempt));
});

/// The test record that best represents the student's current state.
final currentTestForStudentProvider = Provider.family<DrivingTest?, String>((
  ref,
  studentId,
) {
  final tests = ref.watch(testsForStudentProvider(studentId));
  return tests.where((t) => t.status == TestStatus.scheduled).firstOrNull ??
      tests.lastOrNull;
});

/// Scheduled tests from today onwards, soonest first.
final upcomingTestsProvider = Provider<List<DrivingTest>>((ref) {
  final now = ref.watch(clockProvider)();
  final today = DateTime(now.year, now.month, now.day);
  final all = ref.watch(testsProvider).value ?? const [];
  return all
      .where(
        (t) =>
            t.status == TestStatus.scheduled &&
            t.scheduledAt != null &&
            !t.scheduledAt!.isBefore(today),
      )
      .toList()
    ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));
});
