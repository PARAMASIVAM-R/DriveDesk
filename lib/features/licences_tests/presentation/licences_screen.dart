import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../shared/providers/core_providers.dart';
import '../../students/domain/student.dart';
import '../../students/presentation/student_providers.dart';
import '../domain/licence.dart';
import 'licence_providers.dart';

enum _LicenceFilter { all, alerts, noLlr, testBooked }

class LicencesScreen extends ConsumerStatefulWidget {
  const LicencesScreen({super.key});

  @override
  ConsumerState<LicencesScreen> createState() => _LicencesScreenState();
}

class _LicencesScreenState extends ConsumerState<LicencesScreen> {
  _LicenceFilter _filter = _LicenceFilter.all;

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(studentsProvider);
    final now = ref.watch(clockProvider)();
    // Ensure licence/test data is loaded before rendering rows.
    ref.watch(licencesProvider);
    ref.watch(testsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Licences & tests')),
      body: AsyncValueView(
        value: students,
        data: (all) {
          final rows =
              all
                  .where(
                    (s) =>
                        s.status == StudentStatus.active ||
                        s.status == StudentStatus.onHold ||
                        s.status == StudentStatus.completed,
                  )
                  .map((s) {
                    final llr = ref.watch(licenceForStudentProvider(s.id));
                    final test = ref.watch(currentTestForStudentProvider(s.id));
                    return (s, llr, llrStateOf(llr, now), test);
                  })
                  .where(
                    (r) => switch (_filter) {
                      _LicenceFilter.all => true,
                      _LicenceFilter.alerts =>
                        r.$3 == LlrState.expired ||
                            r.$3 == LlrState.expiringSoon,
                      _LicenceFilter.noLlr => r.$3 == LlrState.none,
                      _LicenceFilter.testBooked =>
                        r.$4?.status == TestStatus.scheduled,
                    },
                  )
                  .toList()
                ..sort((a, b) => a.$1.fullName.compareTo(b.$1.fullName));

          return Column(
            children: [
              SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  children: [
                    for (final (f, label) in const [
                      (_LicenceFilter.all, 'All'),
                      (_LicenceFilter.alerts, 'Expiry alerts'),
                      (_LicenceFilter.noLlr, 'No LLR'),
                      (_LicenceFilter.testBooked, 'Test booked'),
                    ]) ...[
                      ChoiceChip(
                        label: Text(label),
                        selected: _filter == f,
                        onSelected: (_) => setState(() => _filter = f),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: rows.isEmpty
                    ? const EmptyState(
                        icon: Icons.badge_outlined,
                        title: 'No matching students',
                      )
                    : ListView.separated(
                        itemCount: rows.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final (s, llr, state, test) = rows[i];
                          final at = test?.scheduledAt;
                          final testText = test == null
                              ? 'No test booked'
                              : 'Test: ${test.status.label}'
                                    '${at != null && test.status == TestStatus.scheduled ? ' · ${formatShortDate(at)}' : ''}';
                          return ListTile(
                            title: Text(s.fullName),
                            subtitle: Text(
                              '${llr?.expiryDate == null ? 'LLR expiry unknown' : 'LLR expires ${formatDate(llr!.expiryDate)}'}\n$testText',
                            ),
                            isThreeLine: true,
                            trailing: StatusChip(
                              label: state.label,
                              color: state.color,
                            ),
                            onTap: () => context.push('/licences/${s.id}'),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
