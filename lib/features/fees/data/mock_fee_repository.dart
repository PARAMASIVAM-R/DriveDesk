import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../shared/data/mock_database.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/fee_repository.dart';
import '../domain/fees.dart';

final feeRepositoryProvider = Provider<FeeRepository>(
  (ref) => MockFeeRepository(ref.watch(mockDatabaseProvider)),
);

class MockFeeRepository implements FeeRepository {
  MockFeeRepository(this._db);

  final MockDatabase _db;

  @override
  Future<List<Payment>> fetchPayments() async => _db.payments.values.toList();

  @override
  Future<Payment> recordPayment(Payment payment) async =>
      _db.payments.putIfAbsent(payment.id, () => payment);

  @override
  Future<Payment> voidPayment(String paymentId, String reason) async {
    final existing = _db.payments[paymentId];
    if (existing == null) throw const AppException('Payment not found.');
    if (existing.isVoided) {
      throw const AppException('Payment is already voided.');
    }
    return _db.payments[paymentId] = existing.voided(reason);
  }

  @override
  Future<List<Installment>> fetchInstallments() async =>
      _db.installments.values.toList();

  @override
  Future<Installment> saveInstallment(Installment installment) async =>
      _db.installments[installment.id] = installment;

  @override
  Future<void> removeInstallment(String installmentId) async =>
      _db.installments.remove(installmentId);
}
