import 'package:flutter_test/flutter_test.dart';
import 'package:warung_kopi_pos/shared/models/app_models.dart';

import 'support/fake_pos_repository.dart';

void main() {
  test('pending checkout uses next transaction code after highest suffix',
      () async {
    final repository = FakePosRepository();
    final now = DateTime.now();
    final datePart =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    repository.addTransactionForTest(
      TransactionRecord(
        id: 'trx-existing-gap',
        transactionCode: 'TRX-$datePart-007',
        customerId: null,
        customerName: 'Umum / Tanpa Nama',
        totalAmount: 0,
        paymentMethod: PaymentMethod.cash,
        amountPaid: 0,
        changeAmount: 0,
        createdAt: now,
        items: const [],
      ),
    );

    final pending = await repository.savePendingTransactionFromCart(
      cart: const {'prd-004': 1},
      customerId: null,
      customerName: 'Umum / Tanpa Nama',
    );

    final transaction = await repository.checkoutPendingTransaction(
      pendingTransactionId: pending.id,
      paymentMethod: PaymentMethod.cash,
    );

    expect(transaction.transactionCode, 'TRX-$datePart-008');
    expect(await repository.fetchPendingTransactions(), isEmpty);
  });
}
