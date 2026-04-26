import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../models/app_models.dart';
import 'app_database.dart';

class PosRepository {
  PosRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<AppProfile> fetchAppProfile() async {
    final db = await _appDatabase.database;
    final rows = await db.query('app_profile', limit: 1);
    if (rows.isEmpty) {
      throw Exception('Profil toko belum tersedia.');
    }
    return _mapAppProfile(rows.first);
  }

  Future<List<Category>> fetchCategories() async {
    final db = await _appDatabase.database;
    final rows = await db.query('categories', orderBy: 'name ASC');
    return rows
        .map(
          (row) => Category(
            id: row.stringValue('id'),
            name: row.stringValue('name'),
            description: row['description'] as String?,
          ),
        )
        .toList();
  }

  Future<List<Product>> fetchProducts() async {
    final db = await _appDatabase.database;
    final rows = await db.query('products', orderBy: 'name ASC');
    return rows.map(_mapProduct).toList();
  }

  Future<List<Customer>> fetchCustomers() async {
    final db = await _appDatabase.database;
    final rows = await db.query('customers', orderBy: 'created_at DESC');
    return rows.map(_mapCustomer).toList();
  }

  Future<List<TransactionRecord>> fetchTransactions() async {
    final db = await _appDatabase.database;
    final transactionRows =
        await db.query('transactions', orderBy: 'created_at DESC');
    final itemRows = await db.query('transaction_items');

    final itemsByTransaction = <String, List<TransactionItem>>{};
    for (final row in itemRows) {
      final transactionId = row.stringValue('transaction_id');
      itemsByTransaction.putIfAbsent(transactionId, () => []);
      itemsByTransaction[transactionId]!.add(
        TransactionItem(
          productId: row.stringValue('product_id'),
          productName: row.stringValue('product_name'),
          quantity: row.intValue('quantity'),
          sellPrice: row.doubleValue('sell_price'),
        ),
      );
    }

    return transactionRows
        .map(
          (row) => TransactionRecord(
            id: row.stringValue('id'),
            transactionCode: row.stringValue('transaction_code'),
            customerId: row['customer_id'] as String?,
            customerName: row.stringValue('customer_name'),
            totalAmount: row.doubleValue('total_amount'),
            paymentMethod: PaymentMethod.values.byName(
              row.stringValue('payment_method'),
            ),
            amountPaid: row.doubleValue('amount_paid'),
            changeAmount: row.doubleValue('change_amount'),
            createdAt: DateTime.parse(row.stringValue('created_at')),
            items: itemsByTransaction[row.stringValue('id')] ?? const [],
            notes: row['notes'] as String?,
          ),
        )
        .toList();
  }

  Future<List<DebtRecord>> fetchDebts() async {
    final db = await _appDatabase.database;
    final rows = await db.query('debts', orderBy: 'created_at DESC');
    return rows
        .map(
          (row) => DebtRecord(
            id: row.stringValue('id'),
            transactionId: row.stringValue('transaction_id'),
            customerId: row.stringValue('customer_id'),
            customerName: row.stringValue('customer_name'),
            originalAmount: row.doubleValue('original_amount'),
            paidAmount: row.doubleValue('paid_amount'),
            createdAt: DateTime.parse(row.stringValue('created_at')),
            updatedAt: DateTime.parse(row.stringValue('updated_at')),
            dueDate: row['due_date'] == null
                ? null
                : DateTime.parse(row.stringValue('due_date')),
            notes: row['notes'] as String?,
          ),
        )
        .toList();
  }

  Future<List<DebtPayment>> fetchPayments() async {
    final db = await _appDatabase.database;
    final rows = await db.query('debt_payments', orderBy: 'paid_at DESC');
    return rows
        .map(
          (row) => DebtPayment(
            id: row.stringValue('id'),
            debtId: row.stringValue('debt_id'),
            customerId: row.stringValue('customer_id'),
            amount: row.doubleValue('amount'),
            paymentMethod: PaymentMethod.values.byName(
              row.stringValue('payment_method'),
            ),
            paidAt: DateTime.parse(row.stringValue('paid_at')),
            notes: row['notes'] as String?,
          ),
        )
        .toList();
  }

  Future<List<StockMovement>> fetchStockMovements() async {
    final db = await _appDatabase.database;
    final rows = await db.query('stock_movements', orderBy: 'created_at DESC');
    return rows
        .map(
          (row) => StockMovement(
            id: row.stringValue('id'),
            productId: row['product_id'] as String?,
            referenceName: row.stringValue('reference_name'),
            quantity: row.doubleValue('quantity'),
            type: StockMovementType.values.byName(row.stringValue('type')),
            createdAt: DateTime.parse(row.stringValue('created_at')),
            notes: row['notes'] as String?,
          ),
        )
        .toList();
  }

  Future<List<OperationalCost>> fetchOperationalCosts() async {
    final db = await _appDatabase.database;
    final rows = await db.query('operational_costs', orderBy: 'month_year ASC');
    return rows
        .map(
          (row) => OperationalCost(
            id: row.stringValue('id'),
            monthYear: DateTime.parse(row.stringValue('month_year')),
            costName: row.stringValue('cost_name'),
            amount: row.doubleValue('amount'),
          ),
        )
        .toList();
  }

  Future<OperationalCost> saveOperationalCost({
    String? id,
    required DateTime monthYear,
    required String costName,
    required double amount,
  }) async {
    final db = await _appDatabase.database;
    final normalizedMonth = DateTime(monthYear.year, monthYear.month, 1);
    if (id == null) {
      final cost = OperationalCost(
        id: 'opc-${DateTime.now().microsecondsSinceEpoch}',
        monthYear: normalizedMonth,
        costName: costName,
        amount: amount,
      );
      await db.insert('operational_costs', _operationalCostValues(cost));
      return cost;
    }

    final existing = await db.query(
      'operational_costs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (existing.isEmpty) {
      throw Exception('Biaya operasional tidak ditemukan.');
    }

    final cost = OperationalCost(
      id: id,
      monthYear: normalizedMonth,
      costName: costName,
      amount: amount,
    );
    await db.update(
      'operational_costs',
      _operationalCostValues(cost),
      where: 'id = ?',
      whereArgs: [id],
    );
    return cost;
  }

  Future<void> deleteOperationalCost(String id) async {
    final db = await _appDatabase.database;
    final existing = await db.query(
      'operational_costs',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (existing.isEmpty) {
      throw Exception('Biaya operasional tidak ditemukan.');
    }
    await db.delete(
      'operational_costs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Customer> saveCustomer({
    String? id,
    required String name,
    required String phone,
    required String address,
    String? notes,
    required bool isActive,
  }) async {
    final db = await _appDatabase.database;
    final now = DateTime.now();

    if (id == null) {
      final customer = Customer(
        id: 'cus-${now.microsecondsSinceEpoch}',
        name: name,
        phone: phone,
        address: address,
        notes: notes,
        isActive: isActive,
        createdAt: now,
      );
      await db.insert('customers', _customerValues(customer));
      return customer;
    }

    final existing = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (existing.isEmpty) {
      throw Exception('Pelanggan tidak ditemukan.');
    }

    final customer = Customer(
      id: id,
      name: name,
      phone: phone,
      address: address,
      notes: notes,
      isActive: isActive,
      createdAt: DateTime.parse(existing.first.stringValue('created_at')),
    );
    await db.update(
      'customers',
      _customerValues(customer),
      where: 'id = ?',
      whereArgs: [id],
    );
    return customer;
  }

  Future<AppProfile> saveAppProfile({
    required String storeName,
    required String storeSubtitle,
    String? ownerName,
    String? photoPath,
  }) async {
    final db = await _appDatabase.database;
    const id = 'store-main';
    final existing = await db.query(
      'app_profile',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    final profile = AppProfile(
      id: id,
      storeName: storeName,
      storeSubtitle: storeSubtitle,
      ownerName: ownerName,
      photoPath: photoPath,
    );
    if (existing.isEmpty) {
      await db.insert('app_profile', _appProfileValues(profile));
    } else {
      await db.update(
        'app_profile',
        _appProfileValues(profile),
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    return profile;
  }

  Future<void> toggleCustomerActive(String customerId) async {
    final db = await _appDatabase.database;
    final existing = await db.query(
      'customers',
      columns: ['is_active'],
      where: 'id = ?',
      whereArgs: [customerId],
      limit: 1,
    );
    if (existing.isEmpty) {
      throw Exception('Pelanggan tidak ditemukan.');
    }

    final currentValue = existing.first.intValue('is_active');
    await db.update(
      'customers',
      {'is_active': currentValue == 1 ? 0 : 1},
      where: 'id = ?',
      whereArgs: [customerId],
    );
  }

  Future<void> saveProduct({
    String? id,
    required String name,
    required String categoryId,
    required double sellPrice,
    required double costPrice,
    required int stockQty,
    required int minStock,
    required String unit,
    String? rackLocation,
    String? imagePath,
  }) async {
    final db = await _appDatabase.database;
    if (id == null) {
      final product = Product(
        id: 'prd-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        categoryId: categoryId,
        sellPrice: sellPrice,
        costPrice: costPrice,
        stockQty: stockQty,
        minStock: minStock,
        unit: unit,
        rackLocation: rackLocation,
        imagePath: imagePath,
      );
      await db.insert('products', _productValues(product));
      return;
    }

    final existing = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (existing.isEmpty) {
      throw Exception('Produk tidak ditemukan.');
    }

    final preserved = _mapProduct(existing.first);
    final product = Product(
      id: preserved.id,
      name: name,
      categoryId: categoryId,
      sellPrice: sellPrice,
      costPrice: costPrice,
      stockQty: stockQty,
      minStock: minStock,
      unit: unit,
      rackLocation: rackLocation,
      imagePath: imagePath,
      isActive: preserved.isActive,
    );
    await db.update(
      'products',
      _productValues(product),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteProduct(String productId) async {
    final db = await _appDatabase.database;
    final existing = await db.query(
      'products',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    if (existing.isEmpty) {
      throw Exception('Produk tidak ditemukan.');
    }

    final usedInTransaction = Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*) FROM transaction_items
            WHERE product_id = ?
            ''',
            [productId],
          ),
        ) ??
        0;
    if (usedInTransaction > 0) {
      throw Exception(
        'Produk sudah dipakai di transaksi dan tidak bisa dihapus.',
      );
    }

    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Future<TransactionRecord> checkout({
    required Map<String, int> cart,
    required String? customerId,
    required String customerName,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    final db = await _appDatabase.database;
    final now = DateTime.now();

    return db.transaction((txn) async {
      final products = await _fetchProductsByIds(txn, cart.keys.toList());
      if (products.length != cart.length) {
        throw Exception('Sebagian produk tidak ditemukan.');
      }

      final items = <TransactionItem>[];
      var totalAmount = 0.0;
      for (final entry in cart.entries) {
        final product = products[entry.key];
        if (product == null) {
          throw Exception('Produk tidak ditemukan.');
        }
        final quantity = entry.value;
        if (quantity <= 0) {
          throw Exception('Jumlah produk harus lebih dari 0.');
        }
        if (quantity > product.stockQty) {
          throw Exception(
            'Stok ${product.name} tidak cukup. Sisa stok ${product.stockQty}.',
          );
        }
        totalAmount += product.sellPrice * quantity;
        items.add(
          TransactionItem(
            productId: product.id,
            productName: product.name,
            quantity: quantity,
            sellPrice: product.sellPrice,
          ),
        );
      }

      final transactionId = 'trx-${now.microsecondsSinceEpoch}';
      final sequence = await _dailyTransactionSequence(txn, now);
      final transactionCode =
          'TRX-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${sequence.toString().padLeft(3, '0')}';
      final transaction = TransactionRecord(
        id: transactionId,
        transactionCode: transactionCode,
        customerId: customerId,
        customerName: customerName,
        totalAmount: totalAmount,
        paymentMethod: paymentMethod,
        amountPaid: paymentMethod == PaymentMethod.bon ? 0 : totalAmount,
        changeAmount: 0,
        createdAt: now,
        items: items,
        notes: notes,
      );

      await txn.insert('transactions', {
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

      for (final item in items) {
        await txn.insert('transaction_items', {
          'transaction_id': transaction.id,
          'product_id': item.productId,
          'product_name': item.productName,
          'quantity': item.quantity,
          'sell_price': item.sellPrice,
        });

        final product = products[item.productId]!;
        await txn.update(
          'products',
          {'stock_qty': max(0, product.stockQty - item.quantity)},
          where: 'id = ?',
          whereArgs: [item.productId],
        );

        await txn.insert('stock_movements', {
          'id': 'stm-${now.microsecondsSinceEpoch}-${item.productId}',
          'product_id': item.productId,
          'reference_name': item.productName,
          'quantity': item.quantity.toDouble(),
          'type': StockMovementType.stockOut.name,
          'notes': 'Transaksi ${transaction.transactionCode}',
          'created_at': now.toIso8601String(),
        });
      }

      if (paymentMethod == PaymentMethod.bon && customerId != null) {
        await txn.insert('debts', {
          'id': 'debt-${now.microsecondsSinceEpoch}',
          'transaction_id': transaction.id,
          'customer_id': customerId,
          'customer_name': customerName,
          'original_amount': totalAmount,
          'paid_amount': 0,
          'due_date': now.add(const Duration(days: 7)).toIso8601String(),
          'notes': 'BON - Belum Lunas',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });
      }

      return transaction;
    });
  }

  Future<void> recordDebtPayment({
    required String debtId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    final db = await _appDatabase.database;
    final now = DateTime.now();

    await db.transaction((txn) async {
      final debtRows = await txn.query(
        'debts',
        where: 'id = ?',
        whereArgs: [debtId],
        limit: 1,
      );
      if (debtRows.isEmpty) {
        throw Exception('Utang tidak ditemukan.');
      }

      final debt = debtRows.first;
      final originalAmount = debt.doubleValue('original_amount');
      final paidAmount = debt.doubleValue('paid_amount');
      final remainingAmount = max(0.0, originalAmount - paidAmount);
      if (amount <= 0) {
        throw Exception('Nominal pembayaran harus lebih dari 0.');
      }
      if (amount > remainingAmount) {
        throw Exception(
          'Nominal pembayaran melebihi sisa utang ${remainingAmount.toStringAsFixed(0)}.',
        );
      }
      final safeAmount = amount;

      await txn.insert('debt_payments', {
        'id': 'pay-${now.microsecondsSinceEpoch}',
        'debt_id': debtId,
        'customer_id': debt.stringValue('customer_id'),
        'amount': safeAmount,
        'payment_method': paymentMethod.name,
        'notes': notes,
        'paid_at': now.toIso8601String(),
      });

      await txn.update(
        'debts',
        {
          'paid_amount': paidAmount + safeAmount,
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [debtId],
      );
    });
  }

  Future<Map<String, Product>> _fetchProductsByIds(
    Transaction txn,
    List<String> ids,
  ) async {
    if (ids.isEmpty) {
      return const {};
    }

    final placeholders = List.filled(ids.length, '?').join(', ');
    final rows = await txn.rawQuery(
      'SELECT * FROM products WHERE id IN ($placeholders)',
      ids,
    );
    return {
      for (final row in rows) row.stringValue('id'): _mapProduct(row),
    };
  }

  Future<int> _dailyTransactionSequence(Transaction txn, DateTime now) async {
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final result = await txn.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM transactions
      WHERE created_at >= ? AND created_at < ?
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    final total = result.first.intValue('total');
    return total + 1;
  }

  Product _mapProduct(Map<String, Object?> row) {
    return Product(
      id: row.stringValue('id'),
      name: row.stringValue('name'),
      categoryId: row.stringValue('category_id'),
      sellPrice: row.doubleValue('sell_price'),
      costPrice: row.doubleValue('cost_price'),
      stockQty: row.intValue('stock_qty'),
      minStock: row.intValue('min_stock'),
      unit: row.stringValue('unit'),
      rackLocation: row['rack_location'] as String?,
      imagePath: row['image_path'] as String?,
      isActive: row.intValue('is_active') == 1,
    );
  }

  AppProfile _mapAppProfile(Map<String, Object?> row) {
    return AppProfile(
      id: row.stringValue('id'),
      storeName: row.stringValue('store_name'),
      storeSubtitle: row.stringValue('store_subtitle'),
      ownerName: row['owner_name'] as String?,
      photoPath: row['photo_path'] as String?,
    );
  }

  Customer _mapCustomer(Map<String, Object?> row) {
    return Customer(
      id: row.stringValue('id'),
      name: row.stringValue('name'),
      phone: row.stringValue('phone'),
      address: row.stringValue('address'),
      notes: row['notes'] as String?,
      isActive: row.intValue('is_active') == 1,
      createdAt: DateTime.parse(row.stringValue('created_at')),
    );
  }

  Map<String, Object?> _productValues(Product product) {
    return {
      'id': product.id,
      'category_id': product.categoryId,
      'name': product.name,
      'sell_price': product.sellPrice,
      'cost_price': product.costPrice,
      'stock_qty': product.stockQty,
      'min_stock': product.minStock,
      'unit': product.unit,
      'rack_location': product.rackLocation,
      'image_path': product.imagePath,
      'is_active': product.isActive ? 1 : 0,
    };
  }

  Map<String, Object?> _appProfileValues(AppProfile profile) {
    return {
      'id': profile.id,
      'store_name': profile.storeName,
      'store_subtitle': profile.storeSubtitle,
      'owner_name': profile.ownerName,
      'photo_path': profile.photoPath,
    };
  }

  Map<String, Object?> _customerValues(Customer customer) {
    return {
      'id': customer.id,
      'name': customer.name,
      'phone': customer.phone,
      'address': customer.address,
      'notes': customer.notes,
      'is_active': customer.isActive ? 1 : 0,
      'created_at': customer.createdAt.toIso8601String(),
    };
  }

  Map<String, Object?> _operationalCostValues(OperationalCost cost) {
    return {
      'id': cost.id,
      'month_year': DateTime(
        cost.monthYear.year,
        cost.monthYear.month,
        1,
      ).toIso8601String(),
      'cost_name': cost.costName,
      'amount': cost.amount,
    };
  }
}

extension on Map<String, Object?> {
  String stringValue(String key) => this[key] as String;

  int intValue(String key) => (this[key] as num).toInt();

  double doubleValue(String key) => (this[key] as num).toDouble();
}
