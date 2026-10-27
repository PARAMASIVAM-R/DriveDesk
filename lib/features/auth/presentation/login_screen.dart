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
      body: Stack(
        children: [
          // Gradient backdrop that the logo and role cards float over.
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 340,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(44),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(right: -60, top: -40, child: _Orb(220, 0.14)),
                  Positioned(left: -50, top: 140, child: _Orb(150, 0.10)),
                ],
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                const SizedBox(height: AppSpacing.lg),
                const Center(child: _AppLogo()),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'DriveDesk',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Driving school manager',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl + AppSpacing.sm),
                Surface3D(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  radius: AppRadius.xl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const DemoBanner(
                        text:
                            'Simulated sign-in for demo purposes. No password '
                            'is checked and no real account is used.',
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xs,
                          AppSpacing.lg,
                          AppSpacing.xs,
                          AppSpacing.sm,
                        ),
                        child: Text(
                          'Continue as',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _RoleCard(
                        icon: Icons.business_center_rounded,
                        color: AppColors.brand,
                        title: 'Owner',
                        subtitle: 'Ramesh Kumar · full school access',
                        onTap: () => session.signIn(
                          role: UserRole.owner,
                          userId: 'stf_owner',
                          displayName: 'Ramesh Kumar',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _RoleCard(
                        icon: Icons.support_agent_rounded,
                        color: AppColors.teal,
                        title: 'Office staff',
                        subtitle: 'Priya Sundaram · students, classes, fees',
                        onTap: () => session.signIn(
                          role: UserRole.officeStaff,
                          userId: 'stf_office',
                          displayName: 'Priya Sundaram',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _RoleCard(
                        icon: Icons.school_rounded,
                        color: AppColors.violet,
                        title: 'Student',
                        subtitle: 'Choose a demo student account',
                        onTap: () => _pickStudent(context, ref),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const GlossyIcon(
        Icons.directions_car_filled_rounded,
        color: Color(0xFFFF8A3D),
        size: 76,
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb(this.size, this.opacity);

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [
            Colors.white.withValues(alpha: opacity * 1.8),
            Colors.white.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Surface3D(
      tint: color,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          GlossyIcon(icon, color: color, size: 48),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(Icons.arrow_forward_rounded, size: 18, color: color),
          ),
        ],
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
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Text(
                  'Demo student accounts (fictional)',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              for (final s in eligible)
                ListTile(
                  leading: Avatar3D(initials: s.initials),
                  title: Text(
                    s.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(s.status.label),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(context, s),
                ),
            ],
          );
        },
      ),
    );
  }
}
