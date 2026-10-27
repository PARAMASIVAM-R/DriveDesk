import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/presentation/session_provider.dart';
import '../../reminders/domain/reminder.dart';
import '../../reminders/presentation/reminder_providers.dart';
import '../../scheduling/presentation/lesson_providers.dart';

class StaffMoreScreen extends ConsumerWidget {
  const StaffMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final draftReminders = ref
        .watch(remindersProvider)
        .where((r) => r.status != ReminderStatus.markedSent)
        .length;
    final pending = ref.watch(pendingRequestsProvider).length;

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          ListTile(
            leading: Avatar3D(
              initials: (session?.displayName ?? '?').characters.first,
            ),
            title: Text(session?.displayName ?? ''),
            subtitle: Text('${session?.role.label ?? ''} · demo account'),
          ),
          const Divider(),
          _Item(
            icon: Icons.badge_outlined,
            title: 'Licences & tests',
            onTap: () => context.push('/licences'),
          ),
          _Item(
            icon: Icons.notifications_outlined,
            title: 'Reminders',
            badge: draftReminders,
            onTap: () => context.push('/reminders'),
          ),
          _Item(
            icon: Icons.swap_horiz,
            title: 'Reschedule requests',
            badge: pending,
            onTap: () => context.push('/lessons/requests'),
          ),
          _Item(
            icon: Icons.groups_outlined,
            title: 'Staff & roles',
            onTap: () => context.push('/team'),
          ),
          _Item(
            icon: Icons.store_outlined,
            title: 'School settings',
            onTap: () => context.push('/settings'),
          ),
          const Divider(),
          _Item(
            icon: Icons.logout,
            title: 'Sign out',
            onTap: () => ref.read(sessionProvider.notifier).signOut(),
          ),
          const Padding(
            padding: AppSpacing.screen,
            child: DemoBanner(
              text:
                  'Frontend demo: data lives in memory and resets when the '
                  'app restarts. No backend or real accounts.',
            ),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.title,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge > 0) Badge(label: Text('$badge')),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}
