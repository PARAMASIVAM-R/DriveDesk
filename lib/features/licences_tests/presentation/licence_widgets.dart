import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/licence.dart';
import 'licence_providers.dart';

/// LLR card for a student, with an expiry indicator.
class LlrCard extends ConsumerWidget {
  const LlrCard({super.key, required this.studentId, this.onEdit});

  final String studentId;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(licenceForStudentProvider(studentId));
    final now = ref.watch(clockProvider)();
    final state = llrStateOf(record, now);
    final expiry = record?.expiryDate;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.badge_outlined),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  "Learner's licence (LLR)",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusChip(label: state.label, color: state.color),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (record == null)
            const Text('No LLR details recorded yet.')
          else ...[
            InfoRow('LLR number', record.llrNumber ?? 'Not recorded'),
            InfoRow(
              'Issued',
              formatDate(record.issueDate, fallback: 'Unknown'),
            ),
            InfoRow(
              'Expires',
              expiry == null
                  ? 'Unknown'
                  : '${formatDate(expiry)} (${relativeDays(daysBetween(now, expiry))})',
            ),
          ],
          if (state == LlrState.expired) ...[
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'This LLR has expired and is not valid for driving on public '
              'roads. A renewal or new LLR is required.',
              style: TextStyle(color: AppColors.danger),
            ),
          ],
          if (onEdit != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: Text(record == null ? 'Add LLR' : 'Edit LLR'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TestAttemptTile extends StatelessWidget {
  const TestAttemptTile({super.key, required this.test, this.trailing});

  final DrivingTest test;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final at = test.scheduledAt;
    final details = [
      at == null
          ? 'Date not set'
          : '${formatShortDate(at)} · ${formatTime(at)}',
      if (test.location.isNotEmpty) test.location,
      if (test.notes.isNotEmpty) test.notes,
    ].join('\n');
    return ListTile(
      leading: GlossyIcon(
        Icons.fact_check_rounded,
        color: test.status.color,
        size: 40,
      ),
      title: Row(
        children: [
          Expanded(child: Text('Driving test · attempt #${test.attempt}')),
          StatusChip(label: test.status.label, color: test.status.color),
        ],
      ),
      subtitle: Text(details),
      isThreeLine: details.contains('\n'),
      trailing: trailing,
    );
  }
}
