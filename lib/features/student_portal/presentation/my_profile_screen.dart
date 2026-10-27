import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/presentation/session_provider.dart';
import '../../settings/presentation/school_providers.dart';
import '../../students/presentation/student_providers.dart';

class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(currentStudentIdProvider);
    final student = id == null ? null : ref.watch(studentByIdProvider(id));
    final school = ref.watch(schoolProvider).value;
    if (student == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.person_off,
          title: 'Profile unavailable',
        ),
      );
    }
    final pkg = ref.watch(packageByIdProvider(student.packageId));
    return Scaffold(
      appBar: AppBar(title: const Text('My profile')),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          Center(child: Avatar3D(initials: student.initials, size: 80)),
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            child: Column(
              children: [
                InfoRow('Name', student.fullName),
                InfoRow('Mobile', student.phone),
                if (student.address.isNotEmpty)
                  InfoRow('Address', student.address),
                InfoRow('Enrolled', formatDate(student.enrolmentDate)),
                InfoRow('Course', pkg?.name ?? '—'),
                InfoRow('Status', student.status.label),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'To update your details, contact the office'
            '${school == null ? '' : ' on ${school.phone}'}.',
          ),
        ],
      ),
    );
  }
}
