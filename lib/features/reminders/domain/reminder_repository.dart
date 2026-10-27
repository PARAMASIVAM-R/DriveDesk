import 'reminder.dart';

/// Stores only the manual/demo status staff record against a reminder.
abstract interface class ReminderRepository {
  Future<Map<String, ReminderStatus>> fetchStatuses();
  Future<void> setStatus(String reminderId, ReminderStatus status);
}
