import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/providers/core_providers.dart';
import '../../fees/presentation/fee_providers.dart';
import '../../licences_tests/domain/licence.dart';
import '../../licences_tests/presentation/licence_providers.dart';
import '../../scheduling/domain/lesson.dart';
import '../../scheduling/presentation/lesson_providers.dart';
import '../../students/domain/student.dart';
import '../../students/presentation/student_providers.dart';

/// An actionable alert on the staff dashboard.
class AttentionItem {
  const AttentionItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String route;
}

final attentionItemsProvider = Provider<List<AttentionItem>>((ref) {
  final now = ref.watch(clockProvider)();
  final students = ref.watch(studentsProvider).value ?? const <Student>[];
  final active = {
    for (final s in students)
      if (s.status == StudentStatus.active || s.status == StudentStatus.onHold)
        s.id: s,
  };
  final items = <AttentionItem>[];

  final pending = ref.watch(pendingRequestsProvider);
  if (pending.isNotEmpty) {
    items.add(
      AttentionItem(
        icon: Icons.swap_horiz,
        color: AppColors.info,
        title: '${pending.length} reschedule request(s) to review',
        subtitle: 'Students are waiting for confirmation',
        route: '/lessons/requests',
      ),
    );
  }

  final lessons = ref.watch(lessonsProvider).value ?? const <Lesson>[];
  for (final l in lessons) {
    if (l.status == LessonStatus.scheduled && l.end.isBefore(now)) {
      items.add(
        AttentionItem(
          icon: Icons.fact_check_outlined,
          color: AppColors.warning,
          title:
              'Mark attendance: ${active[l.studentId]?.fullName ?? 'student'}',
          subtitle:
              '${formatShortDate(l.start)} ${formatTime(l.start)} class has ended',
          route: '/lessons/${l.id}',
        ),
      );
    }
  }

  final licences = ref.watch(licencesProvider).value ?? const <LicenceRecord>[];
  for (final r in licences) {
    final s = active[r.studentId];
    if (s == null) continue;
    final state = llrStateOf(r, now);
    if (state == LlrState.expired || state == LlrState.expiringSoon) {
      items.add(
        AttentionItem(
          icon: Icons.badge_outlined,
          color: state.color,
          title:
              '${s.fullName}: LLR ${state == LlrState.expired ? 'expired' : 'expiring'}',
          subtitle:
              'Expiry ${formatDate(r.expiryDate)} (${relativeDays(daysBetween(now, r.expiryDate!))})',
          route: '/licences/${s.id}',
        ),
      );
    }
  }

  final summaries = ref.watch(feeSummariesProvider);
  for (final s in active.values) {
    final f = summaries[s.id];
    if (f != null && f.hasOverdue) {
      items.add(
        AttentionItem(
          icon: Icons.money_off_outlined,
          color: AppColors.danger,
          title: '${s.fullName}: installment overdue',
          subtitle: '${formatMoney(f.overdueAmount)} overdue',
          route: '/fees/${s.id}',
        ),
      );
    }
  }
  return items;
});

final todaysLessonsProvider = Provider<List<Lesson>>((ref) {
  final now = ref.watch(clockProvider)();
  return ref
      .watch(lessonsOnDayProvider(dateOnly(now)))
      .where((l) => l.rescheduledToId == null)
      .toList();
});

final activeStudentCountProvider = Provider<int>(
  (ref) => (ref.watch(studentsProvider).value ?? const [])
      .where((s) => s.status == StudentStatus.active)
      .length,
);

/// LLRs of active/on-hold students that are expired or expiring soon.
final llrAlertCountProvider = Provider<int>((ref) {
  final now = ref.watch(clockProvider)();
  final students = ref.watch(studentsProvider).value ?? const <Student>[];
  final ids = {
    for (final s in students)
      if (s.status == StudentStatus.active || s.status == StudentStatus.onHold)
        s.id,
  };
  return (ref.watch(licencesProvider).value ?? const [])
      .where((r) => ids.contains(r.studentId))
      .where((r) {
        final st = llrStateOf(r, now);
        return st == LlrState.expired || st == LlrState.expiringSoon;
      })
      .length;
});
