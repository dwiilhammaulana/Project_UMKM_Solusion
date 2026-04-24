import 'package:sqflite/sqflite.dart';

import '../data/seed_data.dart';

Future<void> seedDatabaseIfNeeded(Database db) async {
  final existingCount =
      Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM categories')) ??
          0;
  if (existingCount > 0) {
    return;
  }

  final seed = buildSeedData();
  final batch = db.batch();

  for (final category in seed.categories) {
    batch.insert('categories', {
      'id': category.id,
      'name': category.name,
      'description': category.description,
    });
  }

  for (final product in seed.products) {
    batch.insert('products', {
      'id': product.id,
      'category_id': product.categoryId,
      'name': product.name,
      'sell_price': product.sellPrice,
      'cost_price': product.costPrice,
      'stock_qty': product.stockQty,
      'min_stock': product.minStock,
      'unit': product.unit,
      'rack_location': product.rackLocation,
      'is_active': product.isActive ? 1 : 0,
    });
  }

  for (final customer in seed.customers) {
    batch.insert('customers', {
      'id': customer.id,
      'name': customer.name,
      'phone': customer.phone,
      'address': customer.address,
      'notes': customer.notes,
      'is_active': customer.isActive ? 1 : 0,
      'created_at': customer.createdAt.toIso8601String(),
    });
  }

  for (final transaction in seed.transactions) {
    batch.insert('transactions', {
      'id': transaction.id,
      'transaction_code': transaction.transactionCode,
      'customer_id': transaction.customerId,
      'customer_name': transaction.customerName,
      'total_amount': transaction.totalAmount,
      'payment_method': transaction.paymentMethod.name,
      'amount_paid': transaction.amountPaid,
      'change_amount': transaction.changeAmount,
      'notes': transaction.notes,
      'created_at': transaction.createdAt.toIso8601String(),
    });

    for (final item in transaction.items) {
      batch.insert('transaction_items', {
        'transaction_id': transaction.id,
        'product_id': item.productId,
        'product_name': item.productName,
        'quantity': item.quantity,
        'sell_price': item.sellPrice,
      });
    }
  }

  for (final debt in seed.debts) {
    batch.insert('debts', {
      'id': debt.id,
      'transaction_id': debt.transactionId,
      'customer_id': debt.customerId,
      'customer_name': debt.customerName,
      'original_amount': debt.originalAmount,
      'paid_amount': debt.paidAmount,
      'due_date': debt.dueDate?.toIso8601String(),
      'notes': debt.notes,
      'created_at': debt.createdAt.toIso8601String(),
      'updated_at': debt.updatedAt.toIso8601String(),
    });
  }

  for (final payment in seed.payments) {
    batch.insert('debt_payments', {
      'id': payment.id,
      'debt_id': payment.debtId,
      'customer_id': payment.customerId,
      'amount': payment.amount,
      'payment_method': payment.paymentMethod.name,
      'notes': payment.notes,
      'paid_at': payment.paidAt.toIso8601String(),
    });
  }

  for (final movement in seed.stockMovements) {
    batch.insert('stock_movements', {
      'id': movement.id,
      'product_id': movement.productId,
      'reference_name': movement.referenceName,
      'quantity': movement.quantity,
      'type': movement.type.name,
      'notes': movement.notes,
      'created_at': movement.createdAt.toIso8601String(),
    });
  }

  for (final cost in seed.operationalCosts) {
    batch.insert('operational_costs', {
      'id': cost.id,
      'month_year':
          DateTime(cost.monthYear.year, cost.monthYear.month, 1).toIso8601String(),
      'cost_name': cost.costName,
      'amount': cost.amount,
    });
  }

  await batch.commit(noResult: true);
}
