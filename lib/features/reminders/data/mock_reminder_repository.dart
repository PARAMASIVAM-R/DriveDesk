import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/mock_database.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/reminder.dart';
import '../domain/reminder_repository.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>(
  (ref) => MockReminderRepository(ref.watch(mockDatabaseProvider)),
);

class MockReminderRepository implements ReminderRepository {
  MockReminderRepository(this._db);

  final MockDatabase _db;

  @override
  Future<Map<String, ReminderStatus>> fetchStatuses() async =>
      Map.of(_db.reminderStatuses);

  @override
  Future<void> setStatus(String reminderId, ReminderStatus status) async =>
      _db.reminderStatuses[reminderId] = status;
}
