import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/session_provider.dart';
import '../../settings/presentation/school_providers.dart';

/// Basic read-only view of staff, roles and vehicles for the MVP.
class StaffScreen extends ConsumerWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(staffProvider);
    final vehicles = ref.watch(vehiclesProvider).value ?? const [];
    final isOwner = Permissions.canManageStaff(ref.watch(currentRoleProvider));

    return Scaffold(
      appBar: AppBar(title: const Text('Staff & roles')),
      body: AsyncValueView(
        value: staff,
        data: (members) => ListView(
          padding: AppSpacing.screen,
          children: [
            DemoBanner(
              text: isOwner
                  ? 'Adding and editing staff accounts is planned for a later '
                        'phase.'
                  : 'Only the owner can manage staff. This list is read-only.',
            ),
            const SectionHeader('Team'),
            Card(
              child: Column(
                children: [
                  for (final m in members)
                    ListTile(
                      leading: CircleAvatar(child: Text(m.name[0])),
                      title: Text(m.name),
                      subtitle: Text(m.phone),
                      trailing: Chip(label: Text(m.role.label)),
                    ),
                ],
              ),
            ),
            const SectionHeader('Vehicles'),
            Card(
              child: Column(
                children: [
                  for (final v in vehicles)
                    ListTile(
                      leading: const Icon(Icons.directions_car_outlined),
                      title: Text(v.model),
                      subtitle: Text('${v.registration} · ${v.transmission}'),
                    ),
                ],
              ),
            ),
            const SectionHeader('Role permissions (prototype)'),
            const SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoRow(
                    'Owner',
                    'Everything, incl. voiding payments, '
                        'staff and school settings',
                  ),
                  InfoRow(
                    'Office staff',
                    'Students, classes, licences, '
                        'payments and reminders',
                  ),
                  InfoRow(
                    'Student',
                    'Own records only; can request class '
                        'changes',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
