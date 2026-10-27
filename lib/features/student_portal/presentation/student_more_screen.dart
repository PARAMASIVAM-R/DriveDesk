import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
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
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(session?.displayName ?? ''),
            subtitle: const Text('Student · demo account'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('My reminders'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (reminderCount > 0) Badge(label: Text('$reminderCount')),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => context.push('/me/reminders'),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('My profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/me/profile'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () => ref.read(sessionProvider.notifier).signOut(),
          ),
          const Padding(padding: AppSpacing.screen, child: DemoBanner()),
        ],
      ),
    );
  }
}
