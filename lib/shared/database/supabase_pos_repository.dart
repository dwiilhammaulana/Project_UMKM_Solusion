import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_models.dart';
import 'pos_repository.dart';

class SupabasePosRepository implements PosRepository {
  SupabasePosRepository(this._client);

  final SupabaseClient _client;

  static const _defaultCategories = <Map<String, String?>>[
    {'slug': 'coffee', 'name': 'Kopi', 'description': 'Minuman kopi utama'},
    {'slug': 'food', 'name': 'Makanan', 'description': 'Menu makanan utama'},
    {'slug': 'snack', 'name': 'Jajanan', 'description': 'Snack dan camilan'},
    {'slug': 'raw', 'name': 'Bahan Baku', 'description': 'Bahan baku produksi'},
  ];

  @override
  Future<AppProfile?> fetchAppProfile() async {
    final row = await _client
        .from('app_profile')
        .select()
        .eq('owner_user_id', _requireUserId())
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return _mapAppProfile(Map<String, dynamic>.from(row));
  }

  @override
  Future<List<Category>> fetchCategories() async {
    final rows = await _client
        .from('categories')
        .select()
        .eq('owner_user_id', _requireUserId())
        .order('name');
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(
          (row) => Category(
            id: row.stringValue('id'),
            name: row.stringValue('name'),
            description: row['description'] as String?,
          ),
        )
        .toList();
  }

  @override
  Future<List<Product>> fetchProducts() async {
    final rows = await _client
        .from('products')
        .select()
        .eq('owner_user_id', _requireUserId())
        .order('name');
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_mapProduct)
        .toList();
  }

  @override
  Future<List<Customer>> fetchCustomers() async {
    final rows = await _client
        .from('customers')
        .select()
        .eq('owner_user_id', _requireUserId())
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_mapCustomer)
        .toList();
  }

  @override
  Future<List<TransactionRecord>> fetchTransactions() async {
    final rows = await _client
        .from('transactions')
        .select(
          'id, transaction_code, customer_id, customer_name, total_amount, '
          'payment_method, amount_paid, change_amount, notes, created_at, '
          'transaction_items(product_id, product_name, quantity, sell_price)',
        )
        .eq('owner_user_id', _requireUserId())
        .order('created_at', ascending: false);

    return (rows as List<dynamic>).cast<Map<String, dynamic>>().map((row) {
      final itemRows =
          (row['transaction_items'] as List<dynamic>? ?? const <dynamic>[])
              .cast<Map<String, dynamic>>();
      return TransactionRecord(
        id: row.stringValue('id'),
        transactionCode: row.stringValue('transaction_code'),
        customerId: row['customer_id'] as String?,
        customerName: row.stringValue('customer_name'),
        totalAmount: row.doubleValue('total_amount'),
        paymentMethod:
            PaymentMethod.values.byName(row.stringValue('payment_method')),
        amountPaid: row.doubleValue('amount_paid'),
        changeAmount: row.doubleValue('change_amount'),
        createdAt: DateTime.parse(row.stringValue('created_at')),
        items: itemRows
            .map(
              (item) => TransactionItem(
                productId: item.stringValue('product_id'),
                productName: item.stringValue('product_name'),
                quantity: item.intValue('quantity'),
                sellPrice: item.doubleValue('sell_price'),
              ),
            )
            .toList(),
        notes: row['notes'] as String?,
      );
    }).toList();
  }

  @override
  Future<List<DebtRecord>> fetchDebts() async {
    final rows = await _client
        .from('debts')
        .select()
        .eq('owner_user_id', _requireUserId())
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
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

  @override
  Future<List<DebtPayment>> fetchPayments() async {
    final rows = await _client
        .from('debt_payments')
        .select()
        .eq('owner_user_id', _requireUserId())
        .order('paid_at', ascending: false);
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(
          (row) => DebtPayment(
            id: row.stringValue('id'),
            debtId: row.stringValue('debt_id'),
            customerId: row.stringValue('customer_id'),
            amount: row.doubleValue('amount'),
            paymentMethod:
                PaymentMethod.values.byName(row.stringValue('payment_method')),
            paidAt: DateTime.parse(row.stringValue('paid_at')),
            notes: row['notes'] as String?,
          ),
        )
        .toList();
  }

  @override
  Future<List<StockMovement>> fetchStockMovements() async {
    final rows = await _client
        .from('stock_movements')
        .select()
        .eq('owner_user_id', _requireUserId())
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
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

  @override
  Future<List<OperationalCost>> fetchOperationalCosts() async {
    final rows = await _client
        .from('operational_costs')
        .select()
        .eq('owner_user_id', _requireUserId())
        .order('month_year');
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
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

  @override
  Future<OperationalCost> saveOperationalCost({
    String? id,
    required DateTime monthYear,
    required String costName,
    required double amount,
  }) async {
    final userId = _requireUserId();
    final normalizedMonth = DateTime(monthYear.year, monthYear.month, 1);
    if (id == null) {
      final cost = OperationalCost(
        id: 'opc-${DateTime.now().microsecondsSinceEpoch}',
        monthYear: normalizedMonth,
        costName: costName,
        amount: amount,
      );
      await _client.from('operational_costs').insert({
        ..._operationalCostValues(cost),
        'owner_user_id': userId,
      });
      return cost;
    }

    await _ensureRecordExists('operational_costs', id);
    final cost = OperationalCost(
      id: id,
      monthYear: normalizedMonth,
      costName: costName,
      amount: amount,
    );
    await _client
        .from('operational_costs')
        .update(_operationalCostValues(cost))
        .eq('id', id)
        .eq('owner_user_id', userId);
    return cost;
  }

  @override
  Future<void> deleteOperationalCost(String id) async {
    await _ensureRecordExists('operational_costs', id);
    await _client
        .from('operational_costs')
        .delete()
        .eq('id', id)
        .eq('owner_user_id', _requireUserId());
  }

  @override
  Future<Customer> saveCustomer({
    String? id,
    required String name,
    required String phone,
    required String address,
    String? notes,
    required bool isActive,
  }) async {
    final userId = _requireUserId();
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
      await _client.from('customers').insert({
        ..._customerValues(customer),
        'owner_user_id': userId,
      });
      return customer;
    }

    final existing = await _client
        .from('customers')
        .select('created_at')
        .eq('id', id)
        .eq('owner_user_id', userId)
        .maybeSingle();
    if (existing == null) {
      throw Exception('Pelanggan tidak ditemukan.');
    }

    final customer = Customer(
      id: id,
      name: name,
      phone: phone,
      address: address,
      notes: notes,
      isActive: isActive,
      createdAt: DateTime.parse(
        Map<String, dynamic>.from(existing).stringValue('created_at'),
      ),
    );
    await _client
        .from('customers')
        .update(_customerValues(customer))
        .eq('id', id)
        .eq('owner_user_id', userId);
    return customer;
  }

  @override
  Future<AppProfile> saveAppProfile({
    required String storeName,
    required String storeSubtitle,
    String? ownerName,
    String? photoPath,
  }) async {
    final userId = _requireUserId();
    final existing = await _client
        .from('app_profile')
        .select('id')
        .eq('owner_user_id', userId)
        .maybeSingle();
    final existingMap = existing == null ? null : Map<String, dynamic>.from(existing);
    final profile = AppProfile(
      id: existingMap?.stringValue('id') ?? 'store-$userId',
      storeName: storeName,
      storeSubtitle: storeSubtitle,
      ownerName: ownerName,
      photoPath: photoPath,
    );
    if (existing == null) {
      await _client.from('app_profile').insert({
        ..._appProfileValues(profile),
        'owner_user_id': userId,
      });
      await _ensureDefaultCategories(userId);
    } else {
      await _client
          .from('app_profile')
          .update(_appProfileValues(profile))
          .eq('id', profile.id)
          .eq('owner_user_id', userId);
    }
    return profile;
  }

  @override
  Future<void> toggleCustomerActive(String customerId) async {
    final row = await _client
        .from('customers')
        .select('is_active')
        .eq('id', customerId)
        .eq('owner_user_id', _requireUserId())
        .maybeSingle();
    if (row == null) {
      throw Exception('Pelanggan tidak ditemukan.');
    }
    final current = Map<String, dynamic>.from(row).intValue('is_active');
    await _client
        .from('customers')
        .update({'is_active': current == 1 ? 0 : 1})
        .eq('id', customerId)
        .eq('owner_user_id', _requireUserId());
  }

  @override
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
    final userId = _requireUserId();
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
      await _client.from('products').insert({
        ..._productValues(product),
        'owner_user_id': userId,
      });
      return;
    }

    final existing = await _client
        .from('products')
        .select()
        .eq('id', id)
        .eq('owner_user_id', userId)
        .maybeSingle();
    if (existing == null) {
      throw Exception('Produk tidak ditemukan.');
    }
    final preserved = _mapProduct(Map<String, dynamic>.from(existing));
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
    await _client
        .from('products')
        .update(_productValues(product))
        .eq('id', id)
        .eq('owner_user_id', userId);
  }

  @override
  Future<void> deleteProduct(String productId) async {
    final userId = _requireUserId();
    await _ensureRecordExists('products', productId);
    final usedRows = await _client
        .from('transaction_items')
        .select('id')
        .eq('product_id', productId)
        .eq('owner_user_id', userId)
        .limit(1);
    if ((usedRows as List<dynamic>).isNotEmpty) {
      throw Exception('Produk sudah dipakai di transaksi dan tidak bisa dihapus.');
    }
    await _client
        .from('products')
        .delete()
        .eq('id', productId)
        .eq('owner_user_id', userId);
  }

  @override
  Future<TransactionRecord> checkout({
    required Map<String, int> cart,
    required String? customerId,
    required String customerName,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    final userId = _requireUserId();
    final now = DateTime.now();
    final productRows = await _fetchProductsByIds(cart.keys.toList());
    if (productRows.length != cart.length) {
      throw Exception('Sebagian produk tidak ditemukan.');
    }

    final items = <TransactionItem>[];
    var totalAmount = 0.0;
    for (final entry in cart.entries) {
      final product = productRows[entry.key];
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
    final transactionCode = await _buildTransactionCode(now);
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

    await _client.from('transactions').insert({
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
      'owner_user_id': userId,
    });

    if (items.isNotEmpty) {
      await _client.from('transaction_items').insert(
            items
                .map(
                  (item) => {
                    'transaction_id': transaction.id,
                    'product_id': item.productId,
                    'product_name': item.productName,
                    'quantity': item.quantity,
                    'sell_price': item.sellPrice,
                    'owner_user_id': userId,
                  },
                )
                .toList(),
          );
    }

    for (final item in items) {
      final product = productRows[item.productId]!;
      await _client
          .from('products')
          .update({'stock_qty': max(0, product.stockQty - item.quantity)})
          .eq('id', item.productId)
          .eq('owner_user_id', userId);
    }

    if (items.isNotEmpty) {
      await _client.from('stock_movements').insert(
            items
                .map(
                  (item) => {
                    'id': 'stm-${now.microsecondsSinceEpoch}-${item.productId}',
                    'product_id': item.productId,
                    'reference_name': item.productName,
                    'quantity': item.quantity.toDouble(),
                    'type': StockMovementType.stockOut.name,
                    'notes': 'Transaksi ${transaction.transactionCode}',
                    'created_at': now.toIso8601String(),
                    'owner_user_id': userId,
                  },
                )
                .toList(),
          );
    }

    if (paymentMethod == PaymentMethod.bon && customerId != null) {
      await _client.from('debts').insert({
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
        'owner_user_id': userId,
      });
    }

    return transaction;
  }

  @override
  Future<void> recordDebtPayment({
    required String debtId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    final userId = _requireUserId();
    final now = DateTime.now();
    final row = await _client
        .from('debts')
        .select('customer_id, original_amount, paid_amount')
        .eq('id', debtId)
        .eq('owner_user_id', userId)
        .maybeSingle();
    if (row == null) {
      throw Exception('Utang tidak ditemukan.');
    }
    final debt = Map<String, dynamic>.from(row);
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

    await _client.from('debt_payments').insert({
      'id': 'pay-${now.microsecondsSinceEpoch}',
      'debt_id': debtId,
      'customer_id': debt.stringValue('customer_id'),
      'amount': amount,
      'payment_method': paymentMethod.name,
      'notes': notes,
      'paid_at': now.toIso8601String(),
      'owner_user_id': userId,
    });

    await _client
        .from('debts')
        .update({
          'paid_amount': paidAmount + amount,
          'updated_at': now.toIso8601String(),
        })
        .eq('id', debtId)
        .eq('owner_user_id', userId);
  }

  Future<void> _ensureRecordExists(String table, String id) async {
    final row = await _client
        .from(table)
        .select('id')
        .eq('id', id)
        .eq('owner_user_id', _requireUserId())
        .maybeSingle();
    if (row == null) {
      throw Exception('Data tidak ditemukan.');
    }
  }

  Future<void> _ensureDefaultCategories(String userId) async {
    final rows = await _client
        .from('categories')
        .select('id')
        .eq('owner_user_id', userId)
        .limit(1);
    if ((rows as List<dynamic>).isNotEmpty) {
      return;
    }
    await _client.from('categories').insert(
          _defaultCategories
              .map(
                (category) => {
                  'id': 'cat-$userId-${category['slug']}',
                  'name': category['name'],
                  'description': category['description'],
                  'owner_user_id': userId,
                },
              )
              .toList(),
        );
  }

  Future<Map<String, Product>> _fetchProductsByIds(List<String> ids) async {
    if (ids.isEmpty) {
      return const {};
    }
    final rows = await _client
        .from('products')
        .select()
        .eq('owner_user_id', _requireUserId())
        .inFilter('id', ids);
    return {
      for (final row in (rows as List<dynamic>).cast<Map<String, dynamic>>())
        row.stringValue('id'): _mapProduct(row),
    };
  }

  Future<String> _buildTransactionCode(DateTime now) async {
    final userId = _requireUserId();
    final start = DateTime(now.year, now.month, now.day).toIso8601String();
    final end =
        DateTime(now.year, now.month, now.day + 1).toIso8601String();
    final rows = await _client
        .from('transactions')
        .select('id')
        .eq('owner_user_id', userId)
        .gte('created_at', start)
        .lt('created_at', end);
    final sequence = (rows as List<dynamic>).length + 1;
    return 'TRX-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${sequence.toString().padLeft(3, '0')}';
  }

  Product _mapProduct(Map<String, dynamic> row) {
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

  AppProfile _mapAppProfile(Map<String, dynamic> row) {
    return AppProfile(
      id: row.stringValue('id'),
      storeName: row.stringValue('store_name'),
      storeSubtitle: row.stringValue('store_subtitle'),
      ownerName: row['owner_name'] as String?,
      photoPath: row['photo_path'] as String?,
    );
  }

  Customer _mapCustomer(Map<String, dynamic> row) {
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

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Sesi login tidak ditemukan. Silakan login ulang.');
    }
    return userId;
  }
}

extension on Map<String, dynamic> {
  String stringValue(String key) => this[key] as String;

  int intValue(String key) => (this[key] as num).toInt();

  double doubleValue(String key) => (this[key] as num).toDouble();
}
