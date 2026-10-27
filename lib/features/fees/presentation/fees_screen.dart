import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../students/presentation/student_providers.dart';
import 'fee_providers.dart';

enum _FeeFilter { withBalance, overdue, all }

class FeesScreen extends ConsumerStatefulWidget {
  const FeesScreen({super.key});

  @override
  ConsumerState<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends ConsumerState<FeesScreen> {
  _FeeFilter _filter = _FeeFilter.withBalance;

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(studentsProvider);
    final summaries = ref.watch(feeSummariesProvider);
    final totals = ref.watch(schoolFeeTotalsProvider);
    final loading =
        ref.watch(paymentsProvider).isLoading ||
        ref.watch(installmentsProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Fees')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/fees-pay'),
        icon: const Icon(Icons.currency_rupee),
        label: const Text('Record payment'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : AsyncValueView(
              value: students,
              data: (all) {
                final rows =
                    all.where((s) => billableStatuses.contains(s.status)).where(
                      (s) {
                        final f = summaries[s.id];
                        if (f == null) return false;
                        return switch (_filter) {
                          _FeeFilter.withBalance => f.balance > 0,
                          _FeeFilter.overdue => f.hasOverdue,
                          _FeeFilter.all => true,
                        };
                      },
                    ).toList()..sort(
                      (a, b) => summaries[b.id]!.overdueAmount.compareTo(
                        summaries[a.id]!.overdueAmount,
                      ),
                    );
                return ListView(
                  padding: const EdgeInsets.only(bottom: 88),
                  children: [
                    Padding(
                      padding: AppSpacing.screen,
                      child: Row(
                        children: [
                          Expanded(
                            child: StatTile(
                              label: 'Outstanding',
                              value: formatMoney(totals.outstanding),
                              icon: Icons.account_balance_wallet_outlined,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: StatTile(
                              label: 'Overdue',
                              value: formatMoney(totals.overdue),
                              icon: Icons.money_off_outlined,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.md,
                      ),
                      child: Text(
                        'Collected this month: '
                        '${formatMoney(totals.collectedThisMonth)}',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          for (final (f, label) in const [
                            (_FeeFilter.withBalance, 'With balance'),
                            (_FeeFilter.overdue, 'Overdue'),
                            (_FeeFilter.all, 'All'),
                          ])
                            ChoiceChip(
                              label: Text(label),
                              selected: _filter == f,
                              onSelected: (_) => setState(() => _filter = f),
                            ),
                        ],
                      ),
                    ),
                    if (rows.isEmpty)
                      const EmptyState(
                        icon: Icons.check_circle_outline,
                        title: 'Nothing to show',
                        message: 'No students match this filter.',
                      ),
                    for (final s in rows)
                      ListTile(
                        title: Text(s.fullName),
                        subtitle: Text(
                          'Paid ${formatMoney(summaries[s.id]!.totalPaid)} of '
                          '${formatMoney(s.agreedFee)}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatMoney(summaries[s.id]!.balance),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (summaries[s.id]!.hasOverdue)
                              const Text(
                                'Overdue',
                                style: TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        onTap: () => context.push('/fees/${s.id}'),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
