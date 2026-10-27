import 'package:drive_desk/core/errors/app_exception.dart';
import 'package:drive_desk/features/auth/domain/session.dart';
import 'package:drive_desk/features/auth/presentation/session_provider.dart';
import 'package:drive_desk/features/fees/domain/fees.dart';
import 'package:drive_desk/features/fees/presentation/fee_providers.dart';
import 'package:drive_desk/features/licences_tests/domain/licence.dart';
import 'package:drive_desk/features/licences_tests/presentation/licence_providers.dart';
import 'package:drive_desk/features/reminders/domain/reminder.dart';
import 'package:drive_desk/features/reminders/presentation/reminder_providers.dart';
import 'package:drive_desk/features/scheduling/domain/lesson.dart';
import 'package:drive_desk/features/scheduling/presentation/lesson_providers.dart';
import 'package:drive_desk/features/students/presentation/student_providers.dart';
import 'package:drive_desk/shared/providers/core_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixed "now" so seed data and rules are deterministic.
final now = DateTime(2026, 10, 27, 9, 30);

ProviderContainer makeContainer() {
  final c = ProviderContainer(
    overrides: [clockProvider.overrideWithValue(() => now)],
  );
  addTearDown(c.dispose);
  return c;
}

Future<void> loadAll(ProviderContainer c) async {
  await c.read(studentsProvider.future);
  await c.read(lessonsProvider.future);
  await c.read(rescheduleRequestsProvider.future);
  await c.read(paymentsProvider.future);
  await c.read(installmentsProvider.future);
  await c.read(licencesProvider.future);
  await c.read(testsProvider.future);
  await c.read(reminderStatusesProvider.future);
}

void main() {
  test('seed balances match agreed fee minus valid payments', () async {
    final c = makeContainer();
    await loadAll(c);
    final fees = c.read(feeSummariesProvider);
    expect(fees['stu_001']!.balance, 3000); // 9000 - (4500 + 1500)
    expect(fees['stu_003']!.balance, 0);
    expect(fees['stu_010']!.balance, 1000); // voided 500 excluded
    expect(fees['stu_002']!.hasOverdue, isTrue);
  });

  test('recording the same payment twice creates one record', () async {
    final c = makeContainer();
    await loadAll(c);
    final notifier = c.read(paymentsProvider.notifier);
    final before = c.read(paymentsProvider).value!.length;
    for (var i = 0; i < 2; i++) {
      await notifier.record(
        paymentId: 'pay_fixed',
        studentId: 'stu_001',
        amount: 1000,
        date: DateTime(2026, 10, 27),
        method: PaymentMethod.upi,
      );
    }
    expect(c.read(paymentsProvider).value!.length, before + 1);
    expect(c.read(feeSummaryForStudentProvider('stu_001'))!.balance, 2000);
  });

  test('zero and negative payments are rejected', () async {
    final c = makeContainer();
    await loadAll(c);
    for (final amount in [0.0, -50.0]) {
      expect(
        () => c
            .read(paymentsProvider.notifier)
            .record(
              paymentId: 'bad_$amount',
              studentId: 'stu_001',
              amount: amount,
              date: DateTime(2026, 10, 27),
              method: PaymentMethod.cash,
            ),
        throwsA(isA<AppException>()),
      );
    }
  });

  test('rescheduling keeps the original as cancelled history', () async {
    final c = makeContainer();
    await loadAll(c);
    final original = c.read(lessonByIdProvider('les_020'))!;
    final start = DateTime(2026, 10, 29, 14);
    final moved = await c
        .read(lessonsProvider.notifier)
        .reschedule(
          original,
          start: start,
          end: start.add(const Duration(hours: 1)),
          instructorId: original.instructorId,
          vehicleId: original.vehicleId,
        );
    final old = c.read(lessonByIdProvider('les_020'))!;
    expect(old.status, LessonStatus.cancelled);
    expect(old.rescheduledToId, moved.id);
    expect(moved.rescheduledFromId, 'les_020');
    expect(moved.status, LessonStatus.scheduled);
  });

  test('scheduling over an instructor booking is blocked', () async {
    final c = makeContainer();
    await loadAll(c);
    // Seed: stf_ins1 teaches stu_003 today 16:00-17:00.
    expect(
      () => c
          .read(lessonsProvider.notifier)
          .schedule(
            studentId: 'stu_007',
            start: DateTime(2026, 10, 27, 16, 30),
            end: DateTime(2026, 10, 27, 17, 30),
            instructorId: 'stf_ins1',
          ),
      throwsA(isA<AppException>()),
    );
  });

  test('student can only request changes to their own classes', () async {
    final c = makeContainer();
    await loadAll(c);
    c
        .read(sessionProvider.notifier)
        .signIn(
          role: UserRole.student,
          userId: 'stu_001',
          displayName: 'Arun Prakash',
        );
    final someoneElse = c.read(lessonByIdProvider('les_020'))!; // stu_002
    expect(
      () => c
          .read(rescheduleRequestsProvider.notifier)
          .submit(
            lesson: someoneElse,
            preferredStart: DateTime(2026, 10, 30, 9),
            reason: '',
          ),
      throwsA(isA<AppException>()),
    );
  });

  test('approving a request reschedules the lesson', () async {
    final c = makeContainer();
    await loadAll(c);
    final request = c.read(pendingRequestsProvider).single;
    await c.read(rescheduleRequestsProvider.notifier).approve(request);
    expect(c.read(pendingRequestsProvider), isEmpty);
    final old = c.read(lessonByIdProvider(request.lessonId))!;
    final replacement = c.read(lessonByIdProvider(old.rescheduledToId!))!;
    expect(replacement.start, request.preferredStart);
  });

  test('test reschedule keeps prior booking', () async {
    final c = makeContainer();
    await loadAll(c);
    final scheduled = c.read(currentTestForStudentProvider('stu_001'))!;
    await c
        .read(testsProvider.notifier)
        .reschedule(scheduled, at: DateTime(2026, 11, 10, 10), location: 'RTO');
    final tests = c.read(testsForStudentProvider('stu_001'));
    expect(tests.map((t) => t.status), [
      TestStatus.rescheduled,
      TestStatus.scheduled,
    ]);
  });

  test('cannot record an outcome for a future test', () async {
    final c = makeContainer();
    await loadAll(c);
    final future = c.read(currentTestForStudentProvider('stu_001'))!;
    expect(
      () => c.read(testsProvider.notifier).recordOutcome(future, passed: true),
      throwsA(isA<AppException>()),
    );
  });

  test('reminders cover each type and keep recorded status', () async {
    final c = makeContainer();
    await loadAll(c);
    final reminders = c.read(remindersProvider);
    final types = reminders.map((r) => r.type).toSet();
    expect(
      types,
      containsAll([
        ReminderType.classUpcoming,
        ReminderType.llrExpiry,
        ReminderType.drivingTest,
        ReminderType.installmentDue,
        ReminderType.installmentOverdue,
        ReminderType.classChanged,
      ]),
    );
    expect(
      reminders.firstWhere((r) => r.id == 'inst-ins_004').status,
      ReminderStatus.markedSent,
    );
    // No reminders for enquiry/cancelled students.
    expect(reminders.any((r) => r.studentId == 'stu_009'), isFalse);
    expect(
      c
          .read(remindersForStudentProvider('stu_002'))
          .every((r) => r.studentId == 'stu_002'),
      isTrue,
    );
  });
}
