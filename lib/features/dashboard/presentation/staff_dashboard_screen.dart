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
      body: SafeArea(
        bottom: false,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : _DashboardBody(
                greeting:
                    'Hello, ${session?.displayName.split(' ').first ?? ''}',
                schoolName: school?.name ?? '',
              ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.greeting, required this.schoolName});

  final String greeting;
  final String schoolName;

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
        HeroPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: Colors.white),
                        ),
                        Text(
                          schoolName,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Reminders',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.notifications_rounded),
                    onPressed: () => context.push('/reminders'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                formatDate(now),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${today.length} classes today · '
                '${attention.length} items need attention',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  GlassPill(
                    icon: Icons.account_balance_wallet_rounded,
                    label: '${formatMoney(fees.outstanding)} outstanding',
                  ),
                  const GlassPill(
                    icon: Icons.science_rounded,
                    label: 'Demo data',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.3,
          children: [
            StatTile(
              label: 'Active students',
              value: '${ref.watch(activeStudentCountProvider)}',
              icon: Icons.people_alt_rounded,
              onTap: () => context.go('/staff/students'),
            ),
            StatTile(
              label: "Today's classes",
              value: '${today.length}',
              icon: Icons.event_rounded,
              color: AppColors.teal,
              onTap: () => context.go('/staff/classes'),
            ),
            StatTile(
              label: 'Upcoming tests',
              value: '${upcomingTests.length}',
              icon: Icons.fact_check_rounded,
              color: AppColors.violet,
              onTap: () => context.push('/licences'),
            ),
            StatTile(
              label: 'LLR expiry alerts',
              value: '${ref.watch(llrAlertCountProvider)}',
              icon: Icons.badge_rounded,
              color: AppColors.warning,
              onTap: () => context.push('/licences'),
            ),
            StatTile(
              label: 'Outstanding fees (${fees.studentsWithBalance} students)',
              value: formatMoney(fees.outstanding),
              icon: Icons.account_balance_wallet_rounded,
              color: AppColors.info,
              onTap: () => context.go('/staff/fees'),
            ),
            StatTile(
              label: 'Overdue installments',
              value: formatMoney(fees.overdue),
              icon: Icons.money_off_rounded,
              color: AppColors.danger,
              onTap: () => context.go('/staff/fees'),
            ),
          ],
        ),
        const SectionHeader('Quick actions'),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.person_add_alt_1_rounded,
                label: 'Add student',
                color: AppColors.brand,
                onTap: () => context.push('/students/new'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _QuickAction(
                icon: Icons.event_available_rounded,
                label: 'Schedule class',
                color: AppColors.teal,
                onTap: () => context.push('/lessons/new'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _QuickAction(
                icon: Icons.currency_rupee_rounded,
                label: 'Record payment',
                color: AppColors.success,
                onTap: () => context.push('/fees-pay'),
              ),
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
                    leading: GlossyIcon(a.icon, color: a.color, size: 40),
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
                    leading: const GlossyIcon(
                      Icons.fact_check_rounded,
                      color: AppColors.violet,
                      size: 40,
                    ),
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

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Surface3D(
      tint: color,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: [
          GlossyIcon(icon, color: color, size: 44),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
