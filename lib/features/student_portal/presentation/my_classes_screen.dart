import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../shared/providers/core_providers.dart';
import '../../auth/presentation/session_provider.dart';
import '../../scheduling/domain/lesson.dart';
import '../../scheduling/presentation/lesson_providers.dart';
import '../../scheduling/presentation/lesson_tile.dart';

class MyClassesScreen extends ConsumerWidget {
  const MyClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(currentStudentIdProvider);
    if (id == null) return const SizedBox.shrink();
    final now = ref.watch(clockProvider)();
    final lessons = ref.watch(lessonsForStudentProvider(id));
    final upcoming = lessons
        .where((l) => l.isUpcoming && l.end.isAfter(now))
        .toList()
        .reversed
        .toList();
    final past = lessons
        .where((l) => !(l.isUpcoming && l.end.isAfter(now)))
        .toList();
    final requests = ref.watch(rescheduleRequestsProvider).value ?? const [];
    final myRequests = requests.where((r) => r.studentId == id).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My classes'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Upcoming (${upcoming.length})'),
              Tab(text: 'History (${past.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            upcoming.isEmpty
                ? const EmptyState(
                    icon: Icons.event_available,
                    title: 'No upcoming classes',
                    message: 'The office will schedule your next class.',
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    children: [
                      for (final l in upcoming)
                        _UpcomingLesson(
                          lesson: l,
                          request: myRequests
                              .where(
                                (r) =>
                                    r.lessonId == l.id &&
                                    r.status == RescheduleRequestStatus.pending,
                              )
                              .firstOrNull,
                        ),
                    ],
                  ),
            past.isEmpty
                ? const EmptyState(
                    icon: Icons.history,
                    title: 'No past classes yet',
                  )
                : ListView(
                    children: [
                      for (final l in past)
                        LessonTile(lesson: l, showStudent: false),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingLesson extends StatelessWidget {
  const _UpcomingLesson({required this.lesson, this.request});

  final Lesson lesson;
  final RescheduleRequest? request;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        LessonTile(lesson: lesson, showStudent: false),
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          child: request != null
              ? const StatusChip(
                  label: 'Change requested — awaiting office',
                  color: AppColors.warning,
                )
              : TextButton.icon(
                  onPressed: () => context.push('/me/request/${lesson.id}'),
                  icon: const Icon(Icons.event_repeat),
                  label: const Text('Request change'),
                ),
        ),
        const Divider(),
      ],
    );
  }
}
