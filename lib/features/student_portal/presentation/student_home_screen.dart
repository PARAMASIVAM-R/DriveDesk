import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../shared/providers/core_providers.dart';
import '../../auth/presentation/session_provider.dart';
import '../../fees/presentation/fee_providers.dart';
import '../../licences_tests/domain/licence.dart';
import '../../licences_tests/presentation/licence_providers.dart';
import '../../reminders/presentation/reminder_providers.dart';
import '../../reminders/presentation/reminders_screen.dart';
import '../../scheduling/domain/lesson.dart';
import '../../scheduling/presentation/lesson_providers.dart';
import '../../settings/presentation/school_providers.dart';

class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(currentStudentIdProvider);
    final session = ref.watch(sessionProvider);
    if (id == null) return const SizedBox.shrink();
    final now = ref.watch(clockProvider)();

    final lessons = ref.watch(lessonsForStudentProvider(id));
    final nextLesson = lessons
        .where((l) => l.isUpcoming && l.end.isAfter(now))
        .lastOrNull; // List is newest-first, so last upcoming is soonest.
    final test = ref.watch(currentTestForStudentProvider(id));
    final llr = ref.watch(licenceForStudentProvider(id));
    final llrState = llrStateOf(llr, now);
    final fees = ref.watch(feeSummaryForStudentProvider(id));
    final payments = ref.watch(paymentsForStudentProvider(id));
    final reminders = ref.watch(remindersForStudentProvider(id));
    final completed = lessons
        .where((l) => l.status == LessonStatus.completed)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hi, ${session?.displayName.split(' ').first ?? ''}'),
            Text(
              ref.watch(schoolProvider).value?.name ?? '',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          const DemoBanner(),
          const SizedBox(height: AppSpacing.md),
          _HomeCard(
            icon: Icons.directions_car_outlined,
            title: 'Next class',
            body: nextLesson == null
                ? 'No upcoming class scheduled.'
                : '${formatShortDate(nextLesson.start)} · '
                      '${formatTimeRange(nextLesson.start, nextLesson.end)}\n'
                      '${ref.watch(instructorNameProvider(nextLesson.instructorId))}',
            footer: '$completed classes completed',
            onTap: () => context.go('/me/classes'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _HomeCard(
            icon: Icons.fact_check_outlined,
            title: 'Driving test',
            body: test == null
                ? 'Not booked yet.'
                : test.status == TestStatus.scheduled &&
                      test.scheduledAt != null
                ? '${formatShortDate(test.scheduledAt!)} · ${formatTime(test.scheduledAt!)}\n${test.location}'
                : test.status.label,
            trailing: test == null
                ? null
                : StatusChip(
                    label: test.status.label,
                    color: test.status.color,
                  ),
            onTap: () => context.go('/me/licence'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _HomeCard(
            icon: Icons.badge_outlined,
            title: "Learner's licence",
            body: llr?.expiryDate == null
                ? llrState.label
                : 'Expires ${formatDate(llr!.expiryDate)}',
            trailing: StatusChip(label: llrState.label, color: llrState.color),
            onTap: () => context.go('/me/licence'),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (fees != null)
            _HomeCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Fee balance',
              body: formatMoney(fees.balance),
              footer: fees.nextDue == null
                  ? 'Paid ${formatMoney(fees.totalPaid)} of ${formatMoney(fees.agreedFee)}'
                  : 'Next: ${formatMoney(fees.nextDue!.remaining)} due ${formatDate(fees.nextDue!.installment.dueDate)}',
              trailing: fees.hasOverdue
                  ? const StatusChip(label: 'Overdue', color: AppColors.danger)
                  : null,
              onTap: () => context.go('/me/fees'),
            ),
          SectionHeader(
            'My reminders',
            action: TextButton(
              onPressed: () => context.push('/me/reminders'),
              child: const Text('All'),
            ),
          ),
          if (reminders.isEmpty)
            const Text('No reminders right now.')
          else
            for (final r in reminders.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ReminderCard(
                  reminder: r,
                  showRecipient: false,
                  onTap: () => showReminderPreview(context, r, staff: false),
                ),
              ),
          const SectionHeader('Recent payments'),
          if (payments.where((p) => !p.isVoided).isEmpty)
            const Text('No payments recorded yet.')
          else
            Card(
              child: Column(
                children: [
                  for (final p in payments.where((p) => !p.isVoided).take(3))
                    ListTile(
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: Text(formatMoney(p.amount)),
                      subtitle: Text(
                        '${formatDate(p.date)} · ${p.method.label}',
                      ),
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

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.icon,
    required this.title,
    required this.body,
    this.footer,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? footer;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      body,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (footer != null)
                      Text(footer!, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
