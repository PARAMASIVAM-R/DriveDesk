import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/session_provider.dart';
import '../domain/fees.dart';
import 'fee_providers.dart';

/// Agreed fee, paid amount and balance for one student.
class FeeOverviewCard extends StatelessWidget {
  const FeeOverviewCard({super.key, required this.summary});

  final FeeSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balance = summary.balance;
    final progress = summary.agreedFee <= 0
        ? 1.0
        : (summary.totalPaid / summary.agreedFee).clamp(0.0, 1.0);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Outstanding balance', style: theme.textTheme.bodyMedium),
          Text(
            balance < 0
                ? '${formatMoney(-balance)} credit'
                : formatMoney(balance),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: balance > 0 && summary.hasOverdue
                  ? AppColors.danger
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoRow('Agreed course fee', formatMoney(summary.agreedFee)),
          InfoRow('Paid so far', formatMoney(summary.totalPaid)),
          if (summary.hasOverdue)
            InfoRow('Overdue', formatMoney(summary.overdueAmount)),
        ],
      ),
    );
  }
}

/// Installment schedule (planned amounts) — not actual payments.
class InstallmentList extends ConsumerWidget {
  const InstallmentList({
    super.key,
    required this.summary,
    this.editable = false,
  });

  final FeeSummary summary;
  final bool editable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (summary.installments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text('No installment schedule set.'),
      );
    }
    return Card(
      child: Column(
        children: [
          for (final v in summary.installments)
            ListTile(
              title: Text(formatMoney(v.installment.amountDue)),
              subtitle: Text(
                'Due ${formatDate(v.installment.dueDate)}'
                '${v.status == InstallmentStatus.partlyPaid || (v.status == InstallmentStatus.overdue && v.covered > 0) ? ' · ${formatMoney(v.remaining)} remaining' : ''}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusChip(label: v.status.label, color: v.status.color),
                  if (editable && v.covered == 0)
                    IconButton(
                      tooltip: 'Remove installment',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final ok = await confirm(
                          context,
                          title: 'Remove installment?',
                          message:
                              'This only changes the planned schedule. '
                              'No payment records are affected.',
                          confirmLabel: 'Remove',
                        );
                        if (ok) {
                          await ref
                              .read(installmentsProvider.notifier)
                              .remove(v.installment.id);
                        }
                      },
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Payment transactions, newest first. Voided payments stay visible.
class PaymentList extends ConsumerWidget {
  const PaymentList({super.key, required this.payments});

  final List<Payment> payments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (payments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text('No payments recorded yet.'),
      );
    }
    final canVoid = Permissions.canVoidPayments(ref.watch(currentRoleProvider));
    return Card(
      child: Column(
        children: [
          for (final p in payments)
            ListTile(
              leading: Icon(
                p.isVoided ? Icons.block : Icons.receipt_long_outlined,
                color: p.isVoided ? AppColors.neutral : AppColors.success,
              ),
              title: Text(
                formatMoney(p.amount),
                style: p.isVoided
                    ? const TextStyle(decoration: TextDecoration.lineThrough)
                    : null,
              ),
              subtitle: Text(
                '${formatDate(p.date)} · ${p.method.label}'
                '${p.reference == null ? '' : ' · ${p.reference}'}'
                '${p.isVoided ? '\nVoided: ${p.voidReason}' : ''}',
              ),
              isThreeLine: p.isVoided,
              trailing: canVoid && !p.isVoided
                  ? IconButton(
                      tooltip: 'Void payment',
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _void(context, ref, p),
                    )
                  : null,
            ),
        ],
      ),
    );
  }

  Future<void> _void(BuildContext context, WidgetRef ref, Payment p) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Void payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voiding keeps ${formatMoney(p.amount)} in the history but '
              'excludes it from the balance.',
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Void'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null) return;
    try {
      await ref.read(paymentsProvider.notifier).voidPayment(p, reason);
      if (context.mounted) showMessage(context, 'Payment voided.');
    } catch (e) {
      if (context.mounted) showMessage(context, '$e', error: true);
    }
  }
}
