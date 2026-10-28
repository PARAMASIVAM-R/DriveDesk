import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/theme_mode_selector.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/session_provider.dart';
import '../../reminders/domain/reminder.dart';
import '../../reminders/presentation/reminder_providers.dart';
import '../../scheduling/presentation/lesson_providers.dart';
import 'demo_data_providers.dart';

class StaffMoreScreen extends ConsumerWidget {
  const StaffMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final isOwner = Permissions.canManageStaff(ref.watch(currentRoleProvider));
    final draftReminders = ref
        .watch(remindersProvider)
        .where((r) => r.status != ReminderStatus.markedSent)
        .length;
    final pending = ref.watch(pendingRequestsProvider).length;

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          Surface3D(
            child: Row(
              children: [
                Avatar3D(
                  initials: (session?.displayName ?? '?').characters.first,
                  size: 52,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session?.displayName ?? '',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${session?.role.label ?? ''} · demo account',
                        style: TextStyle(color: context.palette.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader('Manage'),
          MenuTile(
            icon: Icons.badge_rounded,
            title: 'Licences & tests',
            onTap: () => context.push('/licences'),
          ),
          MenuTile(
            icon: Icons.notifications_rounded,
            title: 'Reminders',
            badge: draftReminders,
            onTap: () => context.push('/reminders'),
          ),
          MenuTile(
            icon: Icons.swap_horiz_rounded,
            title: 'Reschedule requests',
            badge: pending,
            onTap: () => context.push('/lessons/requests'),
          ),
          MenuTile(
            icon: Icons.groups_rounded,
            title: 'Staff & vehicles',
            onTap: () => context.push('/team'),
          ),
          MenuTile(
            icon: Icons.store_rounded,
            title: 'School settings',
            onTap: () => context.push('/settings'),
          ),
          const SectionHeader('Appearance'),
          const ThemeModeSelector(),
          const SectionHeader('Account'),
          if (isOwner)
            MenuTile(
              icon: Icons.restart_alt_rounded,
              title: 'Reset demo data',
              color: AppColors.danger,
              onTap: () => _reset(context, ref),
            ),
          MenuTile(
            icon: Icons.logout_rounded,
            title: 'Sign out',
            onTap: () => ref.read(sessionProvider.notifier).signOut(),
          ),
          const SizedBox(height: AppSpacing.md),
          const DemoBanner(
            text:
                'Data is saved on this device only. There is no backend '
                'or real account; records are fictional sample data.',
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final ok = await confirm(
      context,
      title: 'Reset demo data?',
      message:
          'All students, classes, payments and other changes saved on this '
          'device will be replaced with fresh sample data. This cannot be '
          'undone.',
      confirmLabel: 'Reset',
    );
    if (!ok) return;
    await ref.read(resetDemoDataProvider)();
    if (context.mounted) showMessage(context, 'Demo data restored');
  }
}
