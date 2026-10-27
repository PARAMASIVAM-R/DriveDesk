import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../shared/providers/core_providers.dart';
import '../../students/presentation/student_providers.dart';
import 'fee_providers.dart';
import 'fee_widgets.dart';

/// Staff view of one student's fee, installment schedule and payments.
class StudentFeesScreen extends ConsumerWidget {
  const StudentFeesScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(feeSummaryForStudentProvider(studentId));
    final payments = ref.watch(paymentsForStudentProvider(studentId));
    return Scaffold(
      appBar: AppBar(title: Text(ref.watch(studentNameProvider(studentId)))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/fees/$studentId/pay'),
        icon: const Icon(Icons.currency_rupee),
        label: const Text('Record payment'),
      ),
      body: summary == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                96,
              ),
              children: [
                FeeOverviewCard(summary: summary),
                SectionHeader(
                  'Installment schedule',
                  action: TextButton.icon(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (_) => _InstallmentForm(studentId: studentId),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ),
                Text(
                  'Planned due dates. Statuses are worked out from recorded '
                  'payments, oldest installment first.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                InstallmentList(summary: summary, editable: true),
                const SectionHeader('Payment history'),
                PaymentList(payments: payments),
              ],
            ),
    );
  }
}

class _InstallmentForm extends ConsumerStatefulWidget {
  const _InstallmentForm({required this.studentId});

  final String studentId;

  @override
  ConsumerState<_InstallmentForm> createState() => _InstallmentFormState();
}

class _InstallmentFormState extends ConsumerState<_InstallmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  late DateTime _due;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _due = dateOnly(ref.read(clockProvider)()).add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(installmentsProvider.notifier)
          .add(
            studentId: widget.studentId,
            amount: double.parse(_amount.text.trim()),
            dueDate: _due,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        showMessage(context, '$e', error: true);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add installment',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Amount due (₹)'),
              validator: Validators.positiveAmount,
            ),
            const SizedBox(height: AppSpacing.md),
            DateField(
              label: 'Due date',
              value: _due,
              onTap: () async {
                final now = ref.read(clockProvider)();
                final d = await showDatePicker(
                  context: context,
                  initialDate: _due,
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 2),
                );
                if (d != null) setState(() => _due = d);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: const Text('Add installment'),
            ),
          ],
        ),
      ),
    );
  }
}
