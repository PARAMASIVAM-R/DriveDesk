import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../shared/providers/core_providers.dart';
import '../../auth/presentation/session_provider.dart';
import '../../fees/presentation/fee_providers.dart';
import '../../licences_tests/presentation/licence_providers.dart';
import '../../scheduling/presentation/lesson_providers.dart';
import '../../scheduling/presentation/lesson_tile.dart';
import '../../settings/presentation/school_providers.dart';
import '../../students/presentation/student_providers.dart';
import 'dashboard_providers.dart';

class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final school = ref.watch(schoolProvider).value;
    // Wait for the core collections before showing totals.
    final loading = [
      ref.watch(studentsProvider),
      ref.watch(lessonsProvider),
      ref.watch(paymentsProvider),
      ref.watch(installmentsProvider),
      ref.watch(licencesProvider),
      ref.watch(testsProvider),
    ].any((v) => v.isLoading);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, ${session?.displayName.split(' ').first ?? ''}'),
            Text(
              school?.name ?? '',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reminders',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/reminders'),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : const _DashboardBody(),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todaysLessonsProvider);
    final upcomingTests = ref.watch(upcomingTestsProvider);
    final fees = ref.watch(schoolFeeTotalsProvider);
    final attention = ref.watch(attentionItemsProvider);
    final now = ref.watch(clockProvider)();

    return ListView(
      padding: AppSpacing.screen,
      children: [
        const DemoBanner(
          text:
              'Demo data — figures below are calculated from fictional '
              'sample records, not live school data.',
        ),
        const SizedBox(height: AppSpacing.lg),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.45,
          children: [
            StatTile(
              label: 'Active students',
              value: '${ref.watch(activeStudentCountProvider)}',
              icon: Icons.people_outline,
              onTap: () => context.go('/staff/students'),
            ),
            StatTile(
              label: "Today's classes",
              value: '${today.length}',
              icon: Icons.event_outlined,
              onTap: () => context.go('/staff/classes'),
            ),
            StatTile(
              label: 'Upcoming tests',
              value: '${upcomingTests.length}',
              icon: Icons.fact_check_outlined,
              onTap: () => context.push('/licences'),
            ),
            StatTile(
              label: 'LLR expiry alerts',
              value: '${ref.watch(llrAlertCountProvider)}',
              icon: Icons.badge_outlined,
              color: AppColors.warning,
              onTap: () => context.push('/licences'),
            ),
            StatTile(
              label: 'Outstanding fees (${fees.studentsWithBalance} students)',
              value: formatMoney(fees.outstanding),
              icon: Icons.account_balance_wallet_outlined,
              onTap: () => context.go('/staff/fees'),
            ),
            StatTile(
              label: 'Overdue installments',
              value: formatMoney(fees.overdue),
              icon: Icons.money_off_outlined,
              color: AppColors.danger,
              onTap: () => context.go('/staff/fees'),
            ),
          ],
        ),
        const SectionHeader('Quick actions'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ActionChip(
              avatar: const Icon(Icons.person_add_alt),
              label: const Text('Add student'),
              onPressed: () => context.push('/students/new'),
            ),
            ActionChip(
              avatar: const Icon(Icons.event_available),
              label: const Text('Schedule class'),
              onPressed: () => context.push('/lessons/new'),
            ),
            ActionChip(
              avatar: const Icon(Icons.currency_rupee),
              label: const Text('Record payment'),
              onPressed: () => context.push('/fees-pay'),
            ),
          ],
        ),
        SectionHeader('Needs attention (${attention.length})'),
        if (attention.isEmpty)
          const Text('Nothing needs attention right now.')
        else
          Card(
            child: Column(
              children: [
                for (final a in attention.take(8))
                  ListTile(
                    leading: Icon(a.icon, color: a.color),
                    title: Text(a.title),
                    subtitle: Text(a.subtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(a.route),
                  ),
                if (attention.length > 8)
                  ListTile(
                    title: Text('+${attention.length - 8} more'),
                    onTap: () => context.push('/reminders'),
                  ),
              ],
            ),
          ),
        SectionHeader(
          "Today's classes",
          action: TextButton(
            onPressed: () => context.go('/staff/classes'),
            child: const Text('View all'),
          ),
        ),
        if (today.isEmpty)
          const Text('No classes scheduled today.')
        else
          Card(
            child: Column(
              children: [
                for (final l in today)
                  LessonTile(
                    lesson: l,
                    onTap: () => context.push('/lessons/${l.id}'),
                  ),
              ],
            ),
          ),
        const SectionHeader('Upcoming driving tests'),
        if (upcomingTests.isEmpty)
          const Text('No tests scheduled.')
        else
          Card(
            child: Column(
              children: [
                for (final t in upcomingTests.take(5))
                  ListTile(
                    leading: const Icon(Icons.fact_check_outlined),
                    title: Text(ref.watch(studentNameProvider(t.studentId))),
                    subtitle: Text(
                      '${formatShortDate(t.scheduledAt!)} · '
                      '${relativeDays(daysBetween(now, t.scheduledAt!))}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/licences/${t.studentId}'),
                  ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
