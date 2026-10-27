import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/presentation/session_provider.dart';
import '../../fees/presentation/fee_providers.dart';
import '../../fees/presentation/fee_widgets.dart';

/// Read-only fee view for the signed-in student.
class MyFeesScreen extends ConsumerWidget {
  const MyFeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(currentStudentIdProvider);
    if (id == null) return const SizedBox.shrink();
    final summary = ref.watch(feeSummaryForStudentProvider(id));
    final payments = ref.watch(paymentsForStudentProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('My fees')),
      body: summary == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: AppSpacing.screen,
              children: [
                FeeOverviewCard(summary: summary),
                const SectionHeader('Installment schedule'),
                InstallmentList(summary: summary),
                const SectionHeader('Payments'),
                PaymentList(payments: payments),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Payments are recorded by the school office. Online '
                  'payment is not available in this demo.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
    );
  }
}
