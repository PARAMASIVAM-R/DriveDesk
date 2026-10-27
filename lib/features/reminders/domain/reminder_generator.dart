import '../../../core/utils/formatters.dart';
import '../../fees/domain/fees.dart';
import '../../licences_tests/domain/licence.dart';
import '../../scheduling/domain/lesson.dart';
import '../../students/domain/student.dart';
import 'reminder.dart';

/// Derives reminders from current records. Pure function: no I/O, no
/// scheduling, no delivery.
abstract final class ReminderGenerator {
  static const classWindowDays = 1;
  static const testWindowDays = 7;
  static const installmentWindowDays = 7;
  static const changedLookbackDays = 3;

  static List<Reminder> generate({
    required String schoolName,
    required Iterable<Student> students,
    required Iterable<Lesson> lessons,
    required Iterable<LicenceRecord> licences,
    required Iterable<DrivingTest> tests,
    required Map<String, FeeSummary> fees,
    required DateTime now,
  }) {
    final byId = {
      for (final s in students)
        if (s.status == StudentStatus.active ||
            s.status == StudentStatus.onHold)
          s.id: s,
    };
    final out = <Reminder>[];

    Reminder make({
      required String id,
      required Student s,
      required ReminderType type,
      required DateTime dueAt,
      required Urgency urgency,
      required String title,
      required String body,
    }) {
      final first = s.fullName.split(' ').first;
      return Reminder(
        id: id,
        studentId: s.id,
        type: type,
        dueAt: dueAt,
        urgency: urgency,
        title: title,
        message: 'Hello $first,\n\n$body\n\n— $schoolName',
        recipientName: s.fullName,
        recipientPhone: s.phone,
      );
    }

    for (final l in lessons) {
      final s = byId[l.studentId];
      if (s == null) continue;
      final days = daysBetween(now, l.start);
      if (l.status == LessonStatus.scheduled &&
          days >= 0 &&
          days <= classWindowDays &&
          l.start.isAfter(now)) {
        out.add(
          make(
            id: 'class-${l.id}',
            s: s,
            type: ReminderType.classUpcoming,
            dueAt: l.start,
            urgency: days == 0 ? Urgency.high : Urgency.medium,
            title: 'Driving class ${relativeDays(days)}',
            body:
                'This is a reminder of your driving class on '
                '${formatShortDate(l.start)} at ${formatTime(l.start)}. '
                'Please arrive 10 minutes early and bring your LLR.',
          ),
        );
      }
      final recentlyChanged =
          (l.status == LessonStatus.cancelled || l.rescheduledToId != null) &&
          days >= -changedLookbackDays;
      if (recentlyChanged) {
        final moved = l.rescheduledToId != null;
        out.add(
          make(
            id: 'changed-${l.id}',
            s: s,
            type: ReminderType.classChanged,
            dueAt: l.start,
            urgency: Urgency.medium,
            title: moved ? 'Class rescheduled' : 'Class cancelled',
            body: moved
                ? 'Your class on ${formatShortDate(l.start)} at '
                      '${formatTime(l.start)} has been rescheduled. Please '
                      'check the app for the new time.'
                : 'Your class on ${formatShortDate(l.start)} at '
                      '${formatTime(l.start)} has been cancelled. We will '
                      'contact you to arrange a new slot.',
          ),
        );
      }
    }

    for (final r in licences) {
      final s = byId[r.studentId];
      final expiry = r.expiryDate;
      if (s == null || expiry == null) continue;
      final state = llrStateOf(r, now);
      if (state != LlrState.expiringSoon && state != LlrState.expired) {
        continue;
      }
      final expired = state == LlrState.expired;
      out.add(
        make(
          id: 'llr-${r.id}',
          s: s,
          type: ReminderType.llrExpiry,
          dueAt: expiry,
          urgency: expired || daysBetween(now, expiry) <= 7
              ? Urgency.high
              : Urgency.medium,
          title: expired ? 'LLR expired' : 'LLR expiring soon',
          body: expired
              ? 'Your learner\'s licence expired on ${formatDate(expiry)}. '
                    'You cannot drive on public roads with an expired LLR. '
                    'Please contact the office to discuss renewal.'
              : 'Your learner\'s licence expires on ${formatDate(expiry)}. '
                    'Please contact the office to plan your driving test '
                    'before it expires.',
        ),
      );
    }

    for (final t in tests) {
      final s = byId[t.studentId];
      final at = t.scheduledAt;
      if (s == null || at == null || t.status != TestStatus.scheduled) {
        continue;
      }
      final days = daysBetween(now, at);
      if (days < 0 || days > testWindowDays) continue;
      out.add(
        make(
          id: 'test-${t.id}',
          s: s,
          type: ReminderType.drivingTest,
          dueAt: at,
          urgency: days <= 2 ? Urgency.high : Urgency.medium,
          title: 'Driving test ${relativeDays(days)}',
          body:
              'Your driving test is on ${formatShortDate(at)} at '
              '${formatTime(at)}${t.location.isEmpty ? '' : ', ${t.location}'}.'
              ' Please carry your LLR and ID proof.',
        ),
      );
    }

    for (final entry in fees.entries) {
      final s = byId[entry.key];
      if (s == null) continue;
      for (final view in entry.value.installments) {
        final inst = view.installment;
        final days = daysBetween(now, inst.dueDate);
        final overdue = view.status == InstallmentStatus.overdue;
        final dueSoon =
            view.status != InstallmentStatus.paid &&
            !overdue &&
            days <= installmentWindowDays;
        if (!overdue && !dueSoon) continue;
        out.add(
          make(
            id: 'inst-${inst.id}',
            s: s,
            type: overdue
                ? ReminderType.installmentOverdue
                : ReminderType.installmentDue,
            dueAt: inst.dueDate,
            urgency: overdue ? Urgency.high : Urgency.low,
            title: overdue
                ? 'Installment overdue'
                : 'Installment due ${relativeDays(days)}',
            body: overdue
                ? 'Your fee installment of ${formatMoney(view.remaining)} was '
                      'due on ${formatDate(inst.dueDate)}. Please pay at the '
                      'office at your earliest convenience.'
                : 'A fee installment of ${formatMoney(view.remaining)} is '
                      'due on ${formatDate(inst.dueDate)}.',
          ),
        );
      }
    }

    out.sort((a, b) {
      final u = a.urgency.index.compareTo(b.urgency.index);
      return u != 0 ? u : a.dueAt.compareTo(b.dueAt);
    });
    return out;
  }
}
