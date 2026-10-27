import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../students/domain/student.dart';
import '../../students/presentation/student_providers.dart';
import '../domain/session.dart';
import 'session_provider.dart';

/// Demo-only sign in: pick a role (and a student account). No password.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.read(sessionProvider.notifier);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const SizedBox(height: AppSpacing.xl),
            Icon(
              Icons.directions_car_filled,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'DriveDesk',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'Driving school manager',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            const DemoBanner(
              text:
                  'Simulated sign-in for demo purposes. No password is checked '
                  'and no real account is used.',
            ),
            const SectionHeader('Continue as'),
            _RoleCard(
              icon: Icons.business_center_outlined,
              title: 'Owner',
              subtitle: 'Ramesh Kumar · full school access',
              onTap: () => session.signIn(
                role: UserRole.owner,
                userId: 'stf_owner',
                displayName: 'Ramesh Kumar',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _RoleCard(
              icon: Icons.support_agent_outlined,
              title: 'Office staff',
              subtitle: 'Priya Sundaram · students, classes, fees',
              onTap: () => session.signIn(
                role: UserRole.officeStaff,
                userId: 'stf_office',
                displayName: 'Priya Sundaram',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _RoleCard(
              icon: Icons.school_outlined,
              title: 'Student',
              subtitle: 'Choose a demo student account',
              onTap: () => _pickStudent(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStudent(BuildContext context, WidgetRef ref) async {
    final student = await showModalBottomSheet<Student>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const _StudentPicker(),
    );
    if (student == null) return;
    ref
        .read(sessionProvider.notifier)
        .signIn(
          role: UserRole.student,
          userId: student.id,
          displayName: student.fullName,
        );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _StudentPicker extends ConsumerWidget {
  const _StudentPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(studentsProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, controller) => AsyncValueView(
        value: students,
        data: (list) {
          // Enquiries and cancelled students have no portal access.
          final eligible =
              list
                  .where(
                    (s) =>
                        s.status != StudentStatus.enquiry &&
                        s.status != StudentStatus.cancelled,
                  )
                  .toList()
                ..sort((a, b) => a.fullName.compareTo(b.fullName));
          return ListView(
            controller: controller,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Text('Demo student accounts (fictional)'),
              ),
              for (final s in eligible)
                ListTile(
                  leading: CircleAvatar(child: Text(s.initials)),
                  title: Text(s.fullName),
                  subtitle: Text(s.status.label),
                  onTap: () => Navigator.pop(context, s),
                ),
            ],
          );
        },
      ),
    );
  }
}
