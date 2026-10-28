import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../shared/data/mock_database.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/fee_repository.dart';
import '../domain/fees.dart';

final feeRepositoryProvider = Provider<FeeRepository>(
  (ref) => MockFeeRepository(watchPersistedDatabase(ref)),
);

class MockFeeRepository implements FeeRepository {
  MockFeeRepository(this._db);

  final MockDatabase _db;

  @override
  Future<List<Payment>> fetchPayments() async => _db.payments.values.toList();

  @override
  Future<Payment> recordPayment(Payment payment) async {
    if (_db.payments.containsKey(payment.id)) return _db.payments[payment.id]!;
    _db.payments[payment.id] = payment;
    _db.markDirty();
    return payment;
  }

  @override
  Future<Payment> voidPayment(String paymentId, String reason) async {
    final existing = _db.payments[paymentId];
    if (existing == null) throw const AppException('Payment not found.');
    if (existing.isVoided) {
      throw const AppException('Payment is already voided.');
    }
    final voided = _db.payments[paymentId] = existing.voided(reason);
    _db.markDirty();
    return voided;
  }

  @override
  Future<List<Installment>> fetchInstallments() async =>
      _db.installments.values.toList();

  @override
  Future<Installment> saveInstallment(Installment installment) async {
    _db.installments[installment.id] = installment;
    _db.markDirty();
    return installment;
  }

  @override
  Future<void> removeInstallment(String installmentId) async {
    if (_db.installments.remove(installmentId) != null) _db.markDirty();
  }
}
