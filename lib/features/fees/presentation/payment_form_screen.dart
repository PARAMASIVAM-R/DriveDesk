import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../shared/providers/core_providers.dart';
import '../../students/domain/student.dart';
import '../../students/presentation/student_providers.dart';
import '../domain/fees.dart';
import 'fee_providers.dart';

/// Records a payment transaction. When [studentId] is null the student is
/// chosen in the form (dashboard quick action).
class PaymentFormScreen extends ConsumerStatefulWidget {
  const PaymentFormScreen({super.key, this.studentId});

  final String? studentId;

  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reference = TextEditingController();

  /// Generated once so a double-tap or retry cannot create two payments.
  final _paymentId = newId('pay');
  String? _studentId;
  late DateTime _date;
  PaymentMethod _method = PaymentMethod.cash;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _studentId = widget.studentId;
    _date = dateOnly(ref.read(clockProvider)());
  }

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final amount = double.parse(_amount.text.trim());
    final balance =
        ref.read(feeSummaryForStudentProvider(_studentId!))?.balance ?? 0;
    if (amount > balance) {
      final ok = await confirm(
        context,
        title: 'Amount exceeds balance',
        message:
            '${formatMoney(amount)} is more than the outstanding balance of '
            '${formatMoney(balance)}. Record it anyway?',
        confirmLabel: 'Record',
      );
      if (!ok || !mounted) return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(paymentsProvider.notifier)
          .record(
            paymentId: _paymentId,
            studentId: _studentId!,
            amount: amount,
            date: _date,
            method: _method,
            reference: _reference.text,
          );
      if (!mounted) return;
      showMessage(context, 'Payment of ${formatMoney(amount)} recorded.');
      context.pop();
    } catch (e) {
      if (mounted) {
        showMessage(context, '$e', error: true);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final students =
        (ref.watch(studentsProvider).value ?? const <Student>[])
            .where((s) => billableStatuses.contains(s.status))
            .toList()
          ..sort((a, b) => a.fullName.compareTo(b.fullName));
    final summary = _studentId == null
        ? null
        : ref.watch(feeSummaryForStudentProvider(_studentId!));

    return Scaffold(
      appBar: AppBar(title: const Text('Record payment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.screen,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _studentId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Student *'),
              items: [
                for (final s in students)
                  DropdownMenuItem(value: s.id, child: Text(s.fullName)),
              ],
              onChanged: widget.studentId == null
                  ? (v) => setState(() => _studentId = v)
                  : null,
              validator: (v) => v == null ? 'Choose a student' : null,
            ),
            if (summary != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'Outstanding balance: ${formatMoney(summary.balance)}'
                  '${summary.nextDue == null ? '' : ' · next installment ${formatMoney(summary.nextDue!.remaining)} due ${formatDate(summary.nextDue!.installment.dueDate)}'}',
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Amount (₹) *'),
              validator: Validators.positiveAmount,
            ),
            const SizedBox(height: AppSpacing.md),
            DateField(
              label: 'Payment date *',
              value: _date,
              onTap: () async {
                final now = ref.read(clockProvider)();
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(now.year - 1),
                  lastDate: now,
                );
                if (d != null) setState(() => _date = d);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Method', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final m in PaymentMethod.values)
                  ChoiceChip(
                    label: Text(m.label),
                    selected: _method == m,
                    onSelected: (_) => setState(() => _method = m),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _reference,
              decoration: const InputDecoration(
                labelText: 'Reference / receipt no.',
                helperText: 'Optional — e.g. UPI transaction ID',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Record payment'),
            ),
          ],
        ),
      ),
    );
  }
}
