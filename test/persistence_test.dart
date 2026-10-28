import 'dart:convert';

import 'package:drive_desk/features/auth/domain/session.dart';
import 'package:drive_desk/features/auth/presentation/session_provider.dart';
import 'package:drive_desk/features/fees/domain/fees.dart';
import 'package:drive_desk/features/fees/presentation/fee_providers.dart';
import 'package:drive_desk/features/reminders/domain/reminder.dart';
import 'package:drive_desk/features/reminders/presentation/reminder_providers.dart';
import 'package:drive_desk/features/settings/presentation/demo_data_providers.dart';
import 'package:drive_desk/features/settings/presentation/school_providers.dart';
import 'package:drive_desk/features/students/presentation/student_providers.dart';
import 'package:drive_desk/shared/data/local_store.dart';
import 'package:drive_desk/shared/data/mock_database.dart';
import 'package:drive_desk/shared/providers/core_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final now = DateTime(2026, 10, 27, 9, 30);

ProviderContainer makeContainer({
  InMemoryLocalStore? store,
  InMemoryLocalStore? sessionStore,
  MockDatabase? db,
  DemoSession? initialSession,
}) {
  final c = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => now),
      if (store != null) localStoreProvider.overrideWithValue(store),
      if (sessionStore != null)
        sessionStoreProvider.overrideWithValue(sessionStore),
      if (db != null) mockDatabaseProvider.overrideWithValue(db),
      if (initialSession != null)
        initialSessionProvider.overrideWithValue(initialSession),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

/// Lets the debounced saver fire.
Future<void> waitForSave() =>
    Future<void>.delayed(const Duration(milliseconds: 400));

void main() {
  test('seeded database survives a JSON round trip', () {
    final original = MockDatabase.seeded(now);
    final encoded = original.encode();
    final restored = MockDatabase.tryDecode(encoded);
    expect(restored, isNotNull);
    expect(restored!.encode(), encoded);
    expect(restored.students.length, original.students.length);
    expect(restored.payments['pay_011']!.voidReason, isNotNull);
    expect(restored.licences['llr_007']!.expiryDate, isNull);
    expect(
      restored.reminderStatuses['inst-ins_004'],
      ReminderStatus.markedSent,
    );
  });

  test('snapshot with another schema version is rejected', () {
    final json = MockDatabase.seeded(now).toJson()..['version'] = 999;
    expect(MockDatabase.tryDecode(jsonEncode(json)), isNull);
  });

  test('a repository write saves a snapshot to the store', () async {
    final store = InMemoryLocalStore();
    final c = makeContainer(store: store);
    await c.read(paymentsProvider.future);
    expect(store.data, isNull);

    await c
        .read(paymentsProvider.notifier)
        .record(
          paymentId: 'pay_persist',
          studentId: 'stu_001',
          amount: 750,
          date: DateTime(2026, 10, 27),
          method: PaymentMethod.cash,
        );
    await c
        .read(reminderStatusesProvider.notifier)
        .setStatus('class-les_017', ReminderStatus.markedSent);
    await waitForSave();

    expect(store.writeCount, 1, reason: 'writes are debounced');
    final saved = MockDatabase.tryDecode(store.data)!;
    expect(saved.payments['pay_persist']!.amount, 750);
    expect(saved.reminderStatuses['class-les_017'], ReminderStatus.markedSent);
  });

  test('school settings edits and payment voids are persisted', () async {
    final store = InMemoryLocalStore();
    final c = makeContainer(store: store);
    final school = await c.read(schoolProvider.future);
    await c
        .read(schoolProvider.notifier)
        .save(school.copyWith(name: 'Renamed School'));
    final payment = (await c.read(paymentsProvider.future))
        .firstWhere((p) => p.id == 'pay_001');
    await c.read(paymentsProvider.notifier).voidPayment(payment, 'Typo');
    await c.read(snapshotSaverProvider).flush();

    final saved = MockDatabase.tryDecode(store.data)!;
    expect(saved.school.name, 'Renamed School');
    expect(saved.payments['pay_001']!.voidReason, 'Typo');
  });

  test('restored snapshot feeds the providers', () async {
    final db = MockDatabase.seeded(now);
    db.students['stu_001'] = db.students['stu_001']!.copyWith(
      fullName: 'Changed Name',
    );
    final restored = MockDatabase.tryDecode(db.encode())!;
    final c = makeContainer(db: restored);
    await c.read(studentsProvider.future);
    expect(c.read(studentNameProvider('stu_001')), 'Changed Name');
  });

  test('corrupted snapshot falls back to seed data', () {
    for (final bad in ['', '{not json', '[]', '{"version":1}', 'null']) {
      expect(MockDatabase.tryDecode(bad), isNull, reason: bad);
    }
    final db =
        MockDatabase.tryDecode('{"version":1,"school":42}') ??
        MockDatabase.seeded(now);
    expect(db.encode(), MockDatabase.seeded(now).encode());
  });

  test('reset clears storage and restores seed data', () async {
    final store = InMemoryLocalStore();
    final c = makeContainer(store: store);
    final students = await c.read(studentsProvider.future);
    await c
        .read(studentsProvider.notifier)
        .save(students.first.copyWith(fullName: 'Edited'));
    await c.read(snapshotSaverProvider).flush();
    expect(store.data, isNotNull);

    await c.read(resetDemoDataProvider)();
    expect(store.data, isNull);
    await waitForSave();
    expect(store.data, isNull, reason: 'no late save after reset');

    final reloaded = await c.read(studentsProvider.future);
    expect(reloaded.map((s) => s.fullName), isNot(contains('Edited')));
    expect(
      c.read(mockDatabaseProvider).encode(),
      MockDatabase.seeded(now).encode(),
    );
  });

  test('session is persisted on sign in and cleared on sign out', () async {
    final sessionStore = InMemoryLocalStore();
    final c = makeContainer(sessionStore: sessionStore);
    c
        .read(sessionProvider.notifier)
        .signIn(
          role: UserRole.owner,
          userId: 'stf_owner',
          displayName: 'Ramesh Kumar',
        );
    await Future<void>.delayed(Duration.zero);
    final stored = await loadStoredSession(sessionStore);
    expect(stored?.role, UserRole.owner);
    expect(stored?.userId, 'stf_owner');

    final reopened = makeContainer(initialSession: stored);
    expect(reopened.read(sessionProvider)?.displayName, 'Ramesh Kumar');

    c.read(sessionProvider.notifier).signOut();
    await Future<void>.delayed(Duration.zero);
    expect(sessionStore.data, isNull);
    expect(await loadStoredSession(sessionStore), isNull);
  });
}
