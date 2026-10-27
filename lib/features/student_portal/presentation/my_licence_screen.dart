import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/presentation/session_provider.dart';
import '../../licences_tests/presentation/licence_providers.dart';
import '../../licences_tests/presentation/licence_widgets.dart';

/// Read-only licence and test details for the signed-in student.
class MyLicenceScreen extends ConsumerWidget {
  const MyLicenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(currentStudentIdProvider);
    if (id == null) return const SizedBox.shrink();
    final tests = ref.watch(testsForStudentProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('Licence & tests')),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          LlrCard(studentId: id),
          const SectionHeader('Driving tests'),
          if (tests.isEmpty)
            const Text('No test booked yet. The office will arrange it.')
          else
            Card(
              child: Column(
                children: [
                  for (final t in tests.reversed) TestAttemptTile(test: t),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Licence records are maintained by the school office. Contact '
            'them if anything looks wrong.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
