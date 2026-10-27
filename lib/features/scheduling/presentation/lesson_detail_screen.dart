import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../settings/presentation/school_providers.dart';
import '../../students/presentation/student_providers.dart';
import '../domain/lesson.dart';
import 'lesson_providers.dart';

class LessonDetailScreen extends ConsumerWidget {
  const LessonDetailScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lesson = ref.watch(lessonByIdProvider(lessonId));
    if (lesson == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.event_busy,
          title: 'Class not found',
        ),
      );
    }
    final studentName = ref.watch(studentNameProvider(lesson.studentId));
    final editable = lesson.status == LessonStatus.scheduled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Class'),
        actions: [
          if (editable)
            IconButton(
              tooltip: 'Edit assignment',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/lessons/$lessonId/edit'),
            ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        studentName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    StatusChip(
                      label: lesson.status.label,
                      color: lesson.status.color,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                InfoRow('Date', formatShortDate(lesson.start)),
                InfoRow('Time', formatTimeRange(lesson.start, lesson.end)),
                InfoRow(
                  'Instructor',
                  ref.watch(instructorNameProvider(lesson.instructorId)),
                ),
                InfoRow(
                  'Vehicle',
                  ref.watch(vehicleLabelProvider(lesson.vehicleId)),
                ),
                if (lesson.notes.isNotEmpty) InfoRow('Notes', lesson.notes),
              ],
            ),
          ),
          if (lesson.rescheduledFromId != null)
            _LinkTile(
              label: 'Moved from an earlier class',
              lessonId: lesson.rescheduledFromId!,
            ),
          if (lesson.rescheduledToId != null)
            _LinkTile(
              label: 'Rescheduled — view new class',
              lessonId: lesson.rescheduledToId!,
            ),
          TextButton.icon(
            onPressed: () => context.push('/students/${lesson.studentId}'),
            icon: const Icon(Icons.person_outline),
            label: const Text('Open student profile'),
          ),
          if (editable) ...[
            const SectionHeader('Attendance'),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _setStatus(
                      context,
                      ref,
                      lesson,
                      LessonStatus.completed,
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Completed'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _setStatus(context, ref, lesson, LessonStatus.missed),
                    icon: const Icon(Icons.person_off_outlined),
                    label: const Text('Missed'),
                  ),
                ),
              ],
            ),
            const SectionHeader('Change'),
            OutlinedButton.icon(
              onPressed: () => context.push('/lessons/$lessonId/reschedule'),
              icon: const Icon(Icons.event_repeat),
              label: const Text('Reschedule'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
              ),
              onPressed: () =>
                  _setStatus(context, ref, lesson, LessonStatus.cancelled),
              icon: const Icon(Icons.event_busy),
              label: const Text('Cancel class'),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: Text(
                'This class is ${lesson.status.label.toLowerCase()} and kept '
                'for history; it can no longer be changed.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    Lesson lesson,
    LessonStatus status,
  ) async {
    final (title, message) = switch (status) {
      LessonStatus.completed => (
        'Mark as completed?',
        'Confirm the student attended and finished this class.',
      ),
      LessonStatus.missed => (
        'Mark as missed?',
        'The student did not attend this class.',
      ),
      _ => (
        'Cancel this class?',
        'The class will be kept in history as cancelled.',
      ),
    };
    if (!await confirm(context, title: title, message: message)) return;
    try {
      await ref.read(lessonsProvider.notifier).setStatus(lesson, status);
      if (context.mounted) {
        showMessage(context, 'Class marked ${status.label.toLowerCase()}.');
      }
    } catch (e) {
      if (context.mounted) showMessage(context, '$e', error: true);
    }
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.label, required this.lessonId});

  final String label;
  final String lessonId;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.link),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/lessons/$lessonId'),
    );
  }
}
