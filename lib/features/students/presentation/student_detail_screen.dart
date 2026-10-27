import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../fees/presentation/fee_providers.dart';
import '../../licences_tests/presentation/licence_providers.dart';
import '../../licences_tests/presentation/licence_widgets.dart';
import '../../scheduling/domain/lesson.dart';
import '../../scheduling/presentation/lesson_providers.dart';
import '../../scheduling/presentation/lesson_tile.dart';
import 'student_providers.dart';

class StudentDetailScreen extends ConsumerWidget {
  const StudentDetailScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(studentByIdProvider(studentId));
    if (student == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ref.watch(studentsProvider).isLoading
            ? const Center(child: CircularProgressIndicator())
            : const EmptyState(
                icon: Icons.person_off_outlined,
                title: 'Student not found',
              ),
      );
    }
    final pkg = ref.watch(packageByIdProvider(student.packageId));
    final fees = ref.watch(feeSummaryForStudentProvider(studentId));
    final lessons = ref.watch(lessonsForStudentProvider(studentId));
    final upcoming = lessons.where((l) => l.isUpcoming).toList().reversed;
    final completed = lessons
        .where((l) => l.status == LessonStatus.completed)
        .length;
    final test = ref.watch(currentTestForStudentProvider(studentId));

    return Scaffold(
      appBar: AppBar(
        title: Text(student.fullName),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/students/$studentId/edit'),
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
                    CircleAvatar(radius: 28, child: Text(student.initials)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.fullName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(student.phone),
                        ],
                      ),
                    ),
                    StatusChip(
                      label: student.status.label,
                      color: student.status.color,
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.xl),
                InfoRow('Student ID', student.id),
                InfoRow('Enrolled', formatDate(student.enrolmentDate)),
                InfoRow('Course', pkg?.name ?? '—'),
                InfoRow(
                  'Lessons done',
                  '$completed${pkg == null ? '' : ' of ${pkg.lessonCount}'}',
                ),
                if (student.address.isNotEmpty)
                  InfoRow('Address', student.address),
                if (student.dateOfBirth != null)
                  InfoRow('Date of birth', formatDate(student.dateOfBirth)),
                if (student.notes.isNotEmpty) InfoRow('Notes', student.notes),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LlrCard(
            studentId: studentId,
            onEdit: () => context.push('/licences/$studentId'),
          ),
          SectionHeader(
            'Driving test',
            action: TextButton(
              onPressed: () => context.push('/licences/$studentId'),
              child: const Text('Manage'),
            ),
          ),
          Card(
            child: test == null
                ? const ListTile(title: Text('No test booked yet.'))
                : TestAttemptTile(test: test),
          ),
          SectionHeader(
            'Fees',
            action: TextButton(
              onPressed: () => context.push('/fees/$studentId'),
              child: const Text('Details'),
            ),
          ),
          if (fees != null)
            Card(
              child: ListTile(
                title: Text('Balance ${formatMoney(fees.balance)}'),
                subtitle: Text(
                  'Paid ${formatMoney(fees.totalPaid)} of '
                  '${formatMoney(fees.agreedFee)}'
                  '${fees.hasOverdue ? ' · ${formatMoney(fees.overdueAmount)} overdue' : ''}',
                ),
                trailing: FilledButton.tonal(
                  onPressed: () => context.push('/fees/$studentId/pay'),
                  child: const Text('Record'),
                ),
              ),
            ),
          SectionHeader(
            'Upcoming classes',
            action: TextButton(
              onPressed: () =>
                  context.push('/lessons/new?studentId=$studentId'),
              child: const Text('Schedule'),
            ),
          ),
          if (upcoming.isEmpty)
            const Text('No upcoming classes.')
          else
            Card(
              child: Column(
                children: [
                  for (final l in upcoming)
                    LessonTile(
                      lesson: l,
                      showStudent: false,
                      onTap: () => context.push('/lessons/${l.id}'),
                    ),
                ],
              ),
            ),
          const SectionHeader('Class history'),
          if (lessons.where((l) => !l.isUpcoming).isEmpty)
            const Text('No past classes.')
          else
            Card(
              child: Column(
                children: [
                  for (final l in lessons.where((l) => !l.isUpcoming))
                    LessonTile(
                      lesson: l,
                      showStudent: false,
                      onTap: () => context.push('/lessons/${l.id}'),
                    ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
