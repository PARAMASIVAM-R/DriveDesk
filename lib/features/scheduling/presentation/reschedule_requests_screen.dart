import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../students/presentation/student_providers.dart';
import '../domain/lesson.dart';
import 'lesson_providers.dart';

/// Staff review queue for student reschedule requests.
class RescheduleRequestsScreen extends ConsumerWidget {
  const RescheduleRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(rescheduleRequestsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Reschedule requests')),
      body: AsyncValueView(
        value: requests,
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No requests',
            );
          }
          final sorted = [...list]
            ..sort((a, b) {
              final p = a.status.index.compareTo(b.status.index);
              return p != 0 ? p : b.createdAt.compareTo(a.createdAt);
            });
          return ListView.separated(
            padding: AppSpacing.screen,
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) => _RequestCard(request: sorted[i]),
          );
        },
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.request});

  final RescheduleRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lesson = ref.watch(lessonByIdProvider(request.lessonId));
    final pending = request.status == RescheduleRequestStatus.pending;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ref.watch(studentNameProvider(request.studentId)),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusChip(
                label: request.status.label,
                color: request.status.color,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (lesson != null)
            InfoRow(
              'Current',
              '${formatShortDate(lesson.start)} ${formatTime(lesson.start)}',
            ),
          InfoRow(
            'Requested',
            '${formatShortDate(request.preferredStart)} '
                '${formatTime(request.preferredStart)}',
          ),
          if (request.reason.isNotEmpty) InfoRow('Reason', request.reason),
          if (pending) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _act(context, ref, approve: false),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _act(context, ref, approve: true),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _act(
    BuildContext context,
    WidgetRef ref, {
    required bool approve,
  }) async {
    final ok = await confirm(
      context,
      title: approve ? 'Approve request?' : 'Decline request?',
      message: approve
          ? 'The class will be moved to the requested time. The original '
                'slot is kept in history.'
          : 'The class stays at its current time.',
    );
    if (!ok) return;
    final notifier = ref.read(rescheduleRequestsProvider.notifier);
    try {
      approve
          ? await notifier.approve(request)
          : await notifier.decline(request);
      if (context.mounted) {
        showMessage(
          context,
          approve ? 'Class rescheduled.' : 'Request declined.',
        );
      }
    } catch (e) {
      if (context.mounted) showMessage(context, '$e', error: true);
    }
  }
}
