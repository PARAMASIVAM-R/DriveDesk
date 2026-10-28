import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/theme_mode_selector.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/presentation/session_provider.dart';
import '../../reminders/presentation/reminder_providers.dart';

class StudentMoreScreen extends ConsumerWidget {
  const StudentMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final id = ref.watch(currentStudentIdProvider);
    final reminderCount = id == null
        ? 0
        : ref.watch(remindersForStudentProvider(id)).length;
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
                        'Student · demo account',
                        style: TextStyle(color: context.palette.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader('Appearance'),
          const ThemeModeSelector(),
          const SectionHeader('My account'),
          MenuTile(
            icon: Icons.notifications_rounded,
            title: 'My reminders',
            badge: reminderCount,
            onTap: () => context.push('/me/reminders'),
          ),
          MenuTile(
            icon: Icons.person_rounded,
            title: 'My profile',
            onTap: () => context.push('/me/profile'),
          ),
          MenuTile(
            icon: Icons.logout_rounded,
            title: 'Sign out',
            onTap: () => ref.read(sessionProvider.notifier).signOut(),
          ),
          const SizedBox(height: AppSpacing.md),
          const DemoBanner(),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
