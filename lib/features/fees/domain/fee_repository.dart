import 'fees.dart';

abstract interface class FeeRepository {
  Future<List<Payment>> fetchPayments();

  /// Idempotent: recording a payment whose ID already exists is a no-op, so
  /// repeated taps cannot create duplicates.
  Future<Payment> recordPayment(Payment payment);
  Future<Payment> voidPayment(String paymentId, String reason);
  Future<List<Installment>> fetchInstallments();
  Future<Installment> saveInstallment(Installment installment);
  Future<void> removeInstallment(String installmentId);
}
