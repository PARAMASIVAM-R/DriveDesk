import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

enum PaymentMethod {
  cash('Cash'),
  upi('UPI'),
  card('Card'),
  bankTransfer('Bank transfer');

  const PaymentMethod(this.label);
  final String label;
}

/// An actual money transaction. Payments are never edited or deleted;
/// a mistaken payment is voided with a reason so history is preserved.
class Payment {
  const Payment({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.amount,
    required this.date,
    required this.method,
    this.reference,
    this.voidReason,
  });

  final String id;
  final String schoolId;
  final String studentId;
  final double amount;
  final DateTime date;
  final PaymentMethod method;
  final String? reference;
  final String? voidReason;

  bool get isVoided => voidReason != null;

  Map<String, Object?> toJson() => {
    'id': id,
    'schoolId': schoolId,
    'studentId': studentId,
    'amount': amount,
    'date': date.toIso8601String(),
    'method': method.name,
    'reference': reference,
    'voidReason': voidReason,
  };

  factory Payment.fromJson(Map<String, Object?> json) => Payment(
    id: json['id'] as String,
    schoolId: json['schoolId'] as String,
    studentId: json['studentId'] as String,
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String),
    method: PaymentMethod.values.byName(json['method'] as String),
    reference: json['reference'] as String?,
    voidReason: json['voidReason'] as String?,
  );

  Payment voided(String reason) => Payment(
    id: id,
    schoolId: schoolId,
    studentId: studentId,
    amount: amount,
    date: date,
    method: method,
    reference: reference,
    voidReason: reason,
  );
}

/// A planned amount due on a date. This is a schedule, not a transaction.
class Installment {
  const Installment({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.amountDue,
    required this.dueDate,
  });

  final String id;
  final String schoolId;
  final String studentId;
  final double amountDue;
  final DateTime dueDate;

  Map<String, Object?> toJson() => {
    'id': id,
    'schoolId': schoolId,
    'studentId': studentId,
    'amountDue': amountDue,
    'dueDate': dueDate.toIso8601String(),
  };

  factory Installment.fromJson(Map<String, Object?> json) => Installment(
    id: json['id'] as String,
    schoolId: json['schoolId'] as String,
    studentId: json['studentId'] as String,
    amountDue: (json['amountDue'] as num).toDouble(),
    dueDate: DateTime.parse(json['dueDate'] as String),
  );
}

enum InstallmentStatus {
  paid('Paid', AppColors.success),
  partlyPaid('Part paid', AppColors.warning),
  upcoming('Upcoming', AppColors.info),
  overdue('Overdue', AppColors.danger);

  const InstallmentStatus(this.label, this.color);
  final String label;
  final Color color;
}

class InstallmentView {
  const InstallmentView(this.installment, this.covered, this.status);

  final Installment installment;

  /// Portion of this installment covered by recorded payments.
  final double covered;
  final InstallmentStatus status;

  double get remaining => installment.amountDue - covered;
}

class FeeSummary {
  const FeeSummary({
    required this.agreedFee,
    required this.totalPaid,
    required this.installments,
  });

  final double agreedFee;
  final double totalPaid;
  final List<InstallmentView> installments;

  /// Balance = agreed course fee − sum of valid (non-voided) payments.
  double get balance => agreedFee - totalPaid;

  bool get hasOverdue =>
      installments.any((i) => i.status == InstallmentStatus.overdue);

  double get overdueAmount => installments
      .where((i) => i.status == InstallmentStatus.overdue)
      .fold(0, (sum, i) => sum + i.remaining);

  InstallmentView? get nextDue =>
      installments.where((i) => i.status != InstallmentStatus.paid).firstOrNull;
}

abstract final class FeeCalculator {
  /// Builds a student's fee summary. Valid payments are applied to the
  /// installment schedule in due-date order to derive each status.
  static FeeSummary summarise({
    required double agreedFee,
    required Iterable<Payment> payments,
    required Iterable<Installment> installments,
    required DateTime today,
  }) {
    final totalPaid = payments
        .where((p) => !p.isVoided)
        .fold<double>(0, (sum, p) => sum + p.amount);

    final sorted = [...installments]
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    var pool = totalPaid;
    final views = <InstallmentView>[];
    for (final inst in sorted) {
      final covered = pool >= inst.amountDue ? inst.amountDue : pool;
      pool -= covered;
      final InstallmentStatus status;
      if (covered >= inst.amountDue) {
        status = InstallmentStatus.paid;
      } else if (daysBetween(today, inst.dueDate) < 0) {
        status = InstallmentStatus.overdue;
      } else if (covered > 0) {
        status = InstallmentStatus.partlyPaid;
      } else {
        status = InstallmentStatus.upcoming;
      }
      views.add(InstallmentView(inst, covered, status));
    }

    return FeeSummary(
      agreedFee: agreedFee,
      totalPaid: totalPaid,
      installments: views,
    );
  }
}
