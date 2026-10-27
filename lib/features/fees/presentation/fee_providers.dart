import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/ids.dart';
import '../../../shared/providers/core_providers.dart';
import '../../../shared/providers/entity_list_notifier.dart';
import '../../students/domain/student.dart';
import '../../students/presentation/student_providers.dart';
import '../data/mock_fee_repository.dart';
import '../domain/fees.dart';

final paymentsProvider = AsyncNotifierProvider<PaymentsNotifier, List<Payment>>(
  PaymentsNotifier.new,
);

class PaymentsNotifier extends EntityListNotifier<Payment> {
  @override
  String idOf(Payment entity) => entity.id;

  @override
  Future<List<Payment>> build() =>
      ref.watch(feeRepositoryProvider).fetchPayments();

  /// [paymentId] is generated once per form so repeated submits are
  /// idempotent.
  Future<Payment> record({
    required String paymentId,
    required String studentId,
    required double amount,
    required DateTime date,
    required PaymentMethod method,
    String? reference,
  }) async {
    if (!amount.isFinite || amount <= 0) {
      throw const AppException('Payment amount must be greater than zero.');
    }
    if (date.isAfter(ref.read(clockProvider)())) {
      throw const AppException('Payment date cannot be in the future.');
    }
    final saved = await ref
        .read(feeRepositoryProvider)
        .recordPayment(
          Payment(
            id: paymentId,
            schoolId: demoSchoolId,
            studentId: studentId,
            amount: amount,
            date: date,
            method: method,
            reference: (reference == null || reference.trim().isEmpty)
                ? null
                : reference.trim(),
          ),
        );
    upsertAll([saved]);
    return saved;
  }

  Future<void> voidPayment(Payment payment, String reason) async {
    if (reason.trim().isEmpty) {
      throw const AppException('A reason is required to void a payment.');
    }
    upsertAll([
      await ref
          .read(feeRepositoryProvider)
          .voidPayment(payment.id, reason.trim()),
    ]);
  }
}

final installmentsProvider =
    AsyncNotifierProvider<InstallmentsNotifier, List<Installment>>(
      InstallmentsNotifier.new,
    );

class InstallmentsNotifier extends EntityListNotifier<Installment> {
  @override
  String idOf(Installment entity) => entity.id;

  @override
  Future<List<Installment>> build() =>
      ref.watch(feeRepositoryProvider).fetchInstallments();

  Future<void> add({
    required String studentId,
    required double amount,
    required DateTime dueDate,
  }) async {
    if (!amount.isFinite || amount <= 0) {
      throw const AppException('Installment amount must be greater than zero.');
    }
    final saved = await ref
        .read(feeRepositoryProvider)
        .saveInstallment(
          Installment(
            id: newId('ins'),
            schoolId: demoSchoolId,
            studentId: studentId,
            amountDue: amount,
            dueDate: dueDate,
          ),
        );
    upsertAll([saved]);
  }

  Future<void> remove(String installmentId) async {
    await ref.read(feeRepositoryProvider).removeInstallment(installmentId);
    removeWhere((i) => i.id == installmentId);
  }
}

/// Payments of a student, newest first (voided ones included for history).
final paymentsForStudentProvider = Provider.family<List<Payment>, String>((
  ref,
  studentId,
) {
  final all = ref.watch(paymentsProvider).value ?? const [];
  return all.where((p) => p.studentId == studentId).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

/// Fee summaries for every student, keyed by student ID. This is the single
/// place balances are computed.
final feeSummariesProvider = Provider<Map<String, FeeSummary>>((ref) {
  final students = ref.watch(studentsProvider).value ?? const <Student>[];
  final payments = ref.watch(paymentsProvider).value ?? const <Payment>[];
  final installments =
      ref.watch(installmentsProvider).value ?? const <Installment>[];
  final today = ref.watch(clockProvider)();
  return {
    for (final s in students)
      s.id: FeeCalculator.summarise(
        agreedFee: s.agreedFee,
        payments: payments.where((p) => p.studentId == s.id),
        installments: installments.where((i) => i.studentId == s.id),
        today: today,
      ),
  };
});

final feeSummaryForStudentProvider = Provider.family<FeeSummary?, String>(
  (ref, studentId) => ref.watch(feeSummariesProvider)[studentId],
);

/// Statuses whose outstanding balance is still collectable.
const billableStatuses = {
  StudentStatus.active,
  StudentStatus.onHold,
  StudentStatus.completed,
};

class SchoolFeeTotals {
  const SchoolFeeTotals({
    required this.outstanding,
    required this.overdue,
    required this.collectedThisMonth,
    required this.studentsWithBalance,
  });

  final double outstanding;
  final double overdue;
  final double collectedThisMonth;
  final int studentsWithBalance;
}

final schoolFeeTotalsProvider = Provider<SchoolFeeTotals>((ref) {
  final students = ref.watch(studentsProvider).value ?? const <Student>[];
  final summaries = ref.watch(feeSummariesProvider);
  final payments = ref.watch(paymentsProvider).value ?? const <Payment>[];
  final now = ref.watch(clockProvider)();
  var outstanding = 0.0;
  var overdue = 0.0;
  var withBalance = 0;
  for (final s in students.where((s) => billableStatuses.contains(s.status))) {
    final f = summaries[s.id];
    if (f == null) continue;
    if (f.balance > 0) {
      outstanding += f.balance;
      withBalance++;
    }
    overdue += f.overdueAmount;
  }
  final collected = payments
      .where(
        (p) =>
            !p.isVoided && p.date.year == now.year && p.date.month == now.month,
      )
      .fold<double>(0, (sum, p) => sum + p.amount);
  return SchoolFeeTotals(
    outstanding: outstanding,
    overdue: overdue,
    collectedThisMonth: collected,
    studentsWithBalance: withBalance,
  );
});
