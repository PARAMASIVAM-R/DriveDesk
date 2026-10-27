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

    final schoolName = ref.watch(schoolProvider).value?.name ?? '';
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: AppSpacing.screen,
          children: [
            HeroPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, ${session?.displayName.split(' ').first ?? ''}',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(color: Colors.white),
                  ),
                  Text(
                    schoolName,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _ProgressRing(completed: completed),
                  const SizedBox(height: AppSpacing.md),
                  const GlassPill(
                    icon: Icons.science_rounded,
                    label: 'Demo mode · fictional sample data',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _HomeCard(
              icon: Icons.directions_car_rounded,
              color: AppColors.brand,
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
              icon: Icons.fact_check_rounded,
              color: AppColors.violet,
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
              icon: Icons.badge_rounded,
              color: AppColors.teal,
              title: "Learner's licence",
              body: llr?.expiryDate == null
                  ? llrState.label
                  : 'Expires ${formatDate(llr!.expiryDate)}',
              trailing: StatusChip(
                label: llrState.label,
                color: llrState.color,
              ),
              onTap: () => context.go('/me/licence'),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (fees != null)
              _HomeCard(
                icon: Icons.account_balance_wallet_rounded,
                color: AppColors.info,
                title: 'Fee balance',
                body: formatMoney(fees.balance),
                footer: fees.nextDue == null
                    ? 'Paid ${formatMoney(fees.totalPaid)} of ${formatMoney(fees.agreedFee)}'
                    : 'Next: ${formatMoney(fees.nextDue!.remaining)} due ${formatDate(fees.nextDue!.installment.dueDate)}',
                trailing: fees.hasOverdue
                    ? const StatusChip(
                        label: 'Overdue',
                        color: AppColors.danger,
                      )
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
                        leading: const GlossyIcon(
                          Icons.receipt_long_rounded,
                          color: AppColors.success,
                          size: 40,
                        ),
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
      ),
    );
  }
}

/// Progress ring for completed classes, drawn over the hero gradient.
class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.completed});

  final int completed;

  /// Typical course length; only used to fill the ring.
  static const _target = 20;

  @override
  Widget build(BuildContext context) {
    final progress = (completed / _target).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 58,
          height: 58,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 7,
                strokeCap: StrokeCap.round,
                color: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
              ),
              Center(
                child: Text(
                  '$completed',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        const Expanded(
          child: Text(
            'classes completed\nKeep going — every lesson counts.',
            style: TextStyle(color: Colors.white, height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    this.footer,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String? footer;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Surface3D(
      tint: color,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlossyIcon(icon, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (footer != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    footer!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
