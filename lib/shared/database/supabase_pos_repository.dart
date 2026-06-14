import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_models.dart';
import 'pos_repository.dart';

class SupabasePosRepository implements PosRepository {
  SupabasePosRepository(this._client);

  final SupabaseClient _client;
  String? _cachedAuthUserId;
  String? _cachedDataOwnerUserId;
  static final Random _idRandom = Random();
  static const _mediaBucket = 'app-media';
  static const _transactionInsertMaxAttempts = 5;
  static const _transactionSelectColumns =
      'id, transaction_code, customer_id, customer_name, total_amount, '
      'payment_method, amount_paid, change_amount, notes, created_at, '
      'created_by_user_id, created_by_name, '
      'transaction_items(product_id, product_name, quantity, sell_price)';
  static const _legacyTransactionSelectColumns =
      'id, transaction_code, customer_id, customer_name, total_amount, '
      'payment_method, amount_paid, change_amount, notes, created_at, '
      'transaction_items(product_id, product_name, quantity, sell_price)';

  static const _defaultCategories = <Map<String, String?>>[
    {'slug': 'nasi-paket', 'name': 'nasi paket', 'description': null},
    {'slug': 'sembako', 'name': 'sembako', 'description': null},
    {'slug': 'produk-kemasan', 'name': 'produk kemasan', 'description': null},
  ];

  @override
  Future<AppProfile?> fetchAppProfile() async {
    final userId = await _requireDataOwnerUserId();
    final row = await _client
        .from('app_profile')
        .select()
        .eq('owner_user_id', userId)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return _mapAppProfile(Map<String, dynamic>.from(row));
  }

  @override
  Future<List<Category>> fetchCategories() async {
    final userId = await _requireDataOwnerUserId();
    await _ensureDefaultCategories(userId);
    final rows = await _client
        .from('categories')
        .select()
        .eq('owner_user_id', userId)
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
    final userId = await _requireDataOwnerUserId();
    final rows = await _client
        .from('products')
        .select()
        .eq('owner_user_id', userId)
        .order('name');
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_mapProduct)
        .toList();
  }

  @override
  Future<List<Customer>> fetchCustomers() async {
    final userId = await _requireDataOwnerUserId();
    final rows = await _client
        .from('customers')
        .select()
        .eq('owner_user_id', userId)
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_mapCustomer)
        .toList();
  }

  @override
  Future<List<TransactionRecord>> fetchTransactions() async {
    final userId = await _requireDataOwnerUserId();
    List<dynamic> rows;
    try {
      rows = await _client
          .from('transactions')
          .select(_transactionSelectColumns)
          .eq('owner_user_id', userId)
          .order('created_at', ascending: false);
    } on PostgrestException catch (error) {
      if (!_isTransactionCreatorColumnMissing(error)) {
        rethrow;
      }
      rows = await _client
          .from('transactions')
          .select(_legacyTransactionSelectColumns)
          .eq('owner_user_id', userId)
          .order('created_at', ascending: false);
    }

    return rows.cast<Map<String, dynamic>>().map((row) {
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
        createdByUserId: row['created_by_user_id'] as String?,
        createdByName: row['created_by_name'] as String?,
      );
    }).toList();
  }

  @override
  Future<List<PendingTransaction>> fetchPendingTransactions() async {
    final userId = await _requireDataOwnerUserId();
    final rows = await _client
        .from('pending_transactions')
        .select(
          'id, customer_id, customer_name, total_amount, notes, created_at, '
          'pending_transaction_items(product_id, product_name, quantity, sell_price)',
        )
        .eq('owner_user_id', userId)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>).cast<Map<String, dynamic>>().map((row) {
      final itemRows = (row['pending_transaction_items'] as List<dynamic>? ??
              const <dynamic>[])
          .cast<Map<String, dynamic>>();
      return PendingTransaction(
        id: row.stringValue('id'),
        customerId: row['customer_id'] as String?,
        customerName: row.stringValue('customer_name'),
        totalAmount: row.doubleValue('total_amount'),
        createdAt: DateTime.parse(row.stringValue('created_at')),
        items: itemRows
            .map(
              (item) => PendingTransactionItem(
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
    final userId = await _requireDataOwnerUserId();
    final rows = await _client
        .from('debts')
        .select()
        .eq('owner_user_id', userId)
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
    final userId = await _requireDataOwnerUserId();
    final rows = await _client
        .from('debt_payments')
        .select()
        .eq('owner_user_id', userId)
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
    final userId = await _requireDataOwnerUserId();
    final rows = await _client
        .from('stock_movements')
        .select()
        .eq('owner_user_id', userId)
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
    final userId = await _requireDataOwnerUserId();
    final rows = await _client
        .from('operational_costs')
        .select()
        .eq('owner_user_id', userId)
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
    final userId = await _requireDataOwnerUserId();
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
    final userId = await _requireDataOwnerUserId();
    await _client
        .from('operational_costs')
        .delete()
        .eq('id', id)
        .eq('owner_user_id', userId);
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
    final userId = await _requireDataOwnerUserId();
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
    final userId = await _requireDataOwnerUserId();
    final existing = await _client
        .from('app_profile')
        .select('id')
        .eq('owner_user_id', userId)
        .maybeSingle();
    final existingMap =
        existing == null ? null : Map<String, dynamic>.from(existing);
    final profileId = existingMap?.stringValue('id') ?? 'store-$userId';
    final uploadedPhotoPath = await _uploadMediaIfNeeded(
      photoPath,
      userId: userId,
      folder: 'profiles',
      recordId: profileId,
    );
    final profile = AppProfile(
      id: profileId,
      storeName: storeName,
      storeSubtitle: storeSubtitle,
      ownerName: ownerName,
      photoPath: uploadedPhotoPath,
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
    final userId = await _requireDataOwnerUserId();
    final row = await _client
        .from('customers')
        .select('is_active')
        .eq('id', customerId)
        .eq('owner_user_id', userId)
        .maybeSingle();
    if (row == null) {
      throw Exception('Pelanggan tidak ditemukan.');
    }
    final current = Map<String, dynamic>.from(row).intValue('is_active');
    await _client
        .from('customers')
        .update({'is_active': current == 1 ? 0 : 1})
        .eq('id', customerId)
        .eq('owner_user_id', userId);
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
    bool isReady = true,
  }) async {
    final userId = await _requireDataOwnerUserId();
    if (id == null) {
      final productId = 'prd-${DateTime.now().microsecondsSinceEpoch}';
      final uploadedImagePath = await _uploadMediaIfNeeded(
        imagePath,
        userId: userId,
        folder: 'products',
        recordId: productId,
      );
      final product = Product(
        id: productId,
        name: name,
        categoryId: categoryId,
        sellPrice: sellPrice,
        costPrice: costPrice,
        stockQty: stockQty,
        minStock: minStock,
        unit: unit,
        rackLocation: rackLocation,
        imagePath: uploadedImagePath,
        isReady: isReady,
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
    final uploadedImagePath = await _uploadMediaIfNeeded(
      imagePath,
      userId: userId,
      folder: 'products',
      recordId: preserved.id,
    );
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
      imagePath: uploadedImagePath,
      isActive: preserved.isActive,
      isReady: isReady,
    );
    await _client
        .from('products')
        .update(_productValues(product))
        .eq('id', id)
        .eq('owner_user_id', userId);
  }

  @override
  Future<void> deleteProduct(String productId) async {
    final userId = await _requireDataOwnerUserId();
    await _ensureRecordExists('products', productId);
    final usedRows = await _client
        .from('transaction_items')
        .select('id')
        .eq('product_id', productId)
        .eq('owner_user_id', userId)
        .limit(1);
    if ((usedRows as List<dynamic>).isNotEmpty) {
      throw Exception(
          'Produk sudah dipakai di transaksi dan tidak bisa dihapus.');
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
    final userId = await _requireDataOwnerUserId();
    final now = DateTime.now();
    final productRows = await _fetchProductsByIds(cart.keys.toList());
    if (productRows.length != cart.length) {
      throw Exception('Sebagian produk tidak ditemukan.');
    }
    final nasiPaketCategoryIds = await _fetchNasiPaketCategoryIds(userId);

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
      final usesStock = !nasiPaketCategoryIds.contains(product.categoryId);
      if (usesStock && quantity > product.stockQty) {
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

    final transaction = await _insertTransactionWithRetry(
      userId: userId,
      now: now,
      customerId: customerId,
      customerName: customerName,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      items: items,
      notes: notes,
    );

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
      if (!nasiPaketCategoryIds.contains(product.categoryId)) {
        await _client
            .from('products')
            .update({'stock_qty': max(0, product.stockQty - item.quantity)})
            .eq('id', item.productId)
            .eq('owner_user_id', userId);
      }
    }

    final stockItems = items.where((item) {
      final product = productRows[item.productId]!;
      return !nasiPaketCategoryIds.contains(product.categoryId);
    }).toList();
    if (stockItems.isNotEmpty) {
      await _client.from('stock_movements').insert(
            stockItems
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
  Future<PendingTransaction> savePendingTransactionFromCart({
    required Map<String, int> cart,
    required String? customerId,
    required String customerName,
    String? notes,
  }) async {
    if (cart.isEmpty) {
      throw Exception('Keranjang masih kosong.');
    }

    final userId = await _requireDataOwnerUserId();
    final now = DateTime.now();
    final productRows = await _fetchProductsByIds(cart.keys.toList());
    if (productRows.length != cart.length) {
      throw Exception('Sebagian produk tidak ditemukan.');
    }

    final items = <PendingTransactionItem>[];
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
      totalAmount += product.sellPrice * quantity;
      items.add(
        PendingTransactionItem(
          productId: product.id,
          productName: product.name,
          quantity: quantity,
          sellPrice: product.sellPrice,
        ),
      );
    }

    final pending = PendingTransaction(
      id: _newRecordId('tmp', now),
      customerId: customerId,
      customerName: customerName,
      totalAmount: totalAmount,
      createdAt: now,
      items: items,
      notes: notes,
    );

    await _client.from('pending_transactions').insert({
      'id': pending.id,
      'customer_id': pending.customerId,
      'customer_name': pending.customerName,
      'total_amount': pending.totalAmount,
      'notes': pending.notes,
      'created_at': pending.createdAt.toIso8601String(),
      'owner_user_id': userId,
    });

    await _client.from('pending_transaction_items').insert(
          items
              .map(
                (item) => {
                  'pending_transaction_id': pending.id,
                  'product_id': item.productId,
                  'product_name': item.productName,
                  'quantity': item.quantity,
                  'sell_price': item.sellPrice,
                  'owner_user_id': userId,
                },
              )
              .toList(),
        );

    return pending;
  }

  @override
  Future<PendingTransaction> updatePendingTransaction({
    required String id,
    required Map<String, int> cart,
    required String? customerId,
    required String customerName,
    String? notes,
  }) async {
    if (cart.isEmpty) {
      throw Exception(
        'Transaksi berlangsung harus memiliki minimal satu produk.',
      );
    }

    final userId = await _requireDataOwnerUserId();
    final pendingRow = await _client
        .from('pending_transactions')
        .select('id, created_at')
        .eq('id', id)
        .eq('owner_user_id', userId)
        .maybeSingle();
    if (pendingRow == null) {
      throw Exception('Transaksi berlangsung tidak ditemukan.');
    }

    final productRows = await _fetchProductsByIds(cart.keys.toList());
    if (productRows.length != cart.length) {
      throw Exception('Sebagian produk tidak ditemukan.');
    }

    final items = <PendingTransactionItem>[];
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
      totalAmount += product.sellPrice * quantity;
      items.add(
        PendingTransactionItem(
          productId: product.id,
          productName: product.name,
          quantity: quantity,
          sellPrice: product.sellPrice,
        ),
      );
    }

    await _client
        .from('pending_transactions')
        .update({
          'customer_id': customerId,
          'customer_name': customerName,
          'total_amount': totalAmount,
          'notes': notes,
        })
        .eq('id', id)
        .eq('owner_user_id', userId);

    await _client
        .from('pending_transaction_items')
        .delete()
        .eq('pending_transaction_id', id)
        .eq('owner_user_id', userId);

    await _client.from('pending_transaction_items').insert(
          items
              .map(
                (item) => {
                  'pending_transaction_id': id,
                  'product_id': item.productId,
                  'product_name': item.productName,
                  'quantity': item.quantity,
                  'sell_price': item.sellPrice,
                  'owner_user_id': userId,
                },
              )
              .toList(),
        );

    return PendingTransaction(
      id: id,
      customerId: customerId,
      customerName: customerName,
      totalAmount: totalAmount,
      createdAt: DateTime.parse(pendingRow.stringValue('created_at')),
      items: items,
      notes: notes,
    );
  }

  @override
  Future<TransactionRecord> checkoutPendingTransaction({
    required String pendingTransactionId,
    required PaymentMethod paymentMethod,
  }) async {
    final userId = await _requireDataOwnerUserId();
    final now = DateTime.now();
    final row = await _client
        .from('pending_transactions')
        .select(
          'id, customer_id, customer_name, total_amount, notes, created_at, '
          'pending_transaction_items(product_id, product_name, quantity, sell_price)',
        )
        .eq('id', pendingTransactionId)
        .eq('owner_user_id', userId)
        .maybeSingle();
    if (row == null) {
      throw Exception('Transaksi berlangsung tidak ditemukan.');
    }

    final pending = Map<String, dynamic>.from(row);
    final itemRows = (pending['pending_transaction_items'] as List<dynamic>? ??
            const <dynamic>[])
        .cast<Map<String, dynamic>>();
    if (itemRows.isEmpty) {
      throw Exception('Transaksi berlangsung belum memiliki item.');
    }

    final items = itemRows
        .map(
          (item) => TransactionItem(
            productId: item.stringValue('product_id'),
            productName: item.stringValue('product_name'),
            quantity: item.intValue('quantity'),
            sellPrice: item.doubleValue('sell_price'),
          ),
        )
        .toList();
    final productRows =
        await _fetchProductsByIds(items.map((item) => item.productId).toList());
    final nasiPaketCategoryIds = await _fetchNasiPaketCategoryIds(userId);
    if (productRows.length != items.length) {
      throw Exception('Sebagian produk tidak ditemukan.');
    }

    for (final item in items) {
      final product = productRows[item.productId];
      if (product == null) {
        throw Exception('Produk tidak ditemukan.');
      }
      if (!nasiPaketCategoryIds.contains(product.categoryId) &&
          item.quantity > product.stockQty) {
        throw Exception(
          'Stok ${item.productName} tidak cukup. Sisa stok ${product.stockQty}.',
        );
      }
    }

    final totalAmount = items.fold(0.0, (sum, item) => sum + item.subtotal);
    final customerId = pending['customer_id'] as String?;
    final customerName = pending.stringValue('customer_name');
    final transaction = await _insertTransactionWithRetry(
      userId: userId,
      now: now,
      customerId: customerId,
      customerName: customerName,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      items: items,
      notes: pending['notes'] as String?,
    );

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

    for (final item in items) {
      final product = productRows[item.productId]!;
      if (!nasiPaketCategoryIds.contains(product.categoryId)) {
        await _client
            .from('products')
            .update({'stock_qty': max(0, product.stockQty - item.quantity)})
            .eq('id', item.productId)
            .eq('owner_user_id', userId);
      }
    }

    final stockItems = items.where((item) {
      final product = productRows[item.productId]!;
      return !nasiPaketCategoryIds.contains(product.categoryId);
    }).toList();
    if (stockItems.isNotEmpty) {
      await _client.from('stock_movements').insert(
            stockItems
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

    await _client
        .from('pending_transactions')
        .delete()
        .eq('id', pendingTransactionId)
        .eq('owner_user_id', userId);

    return transaction;
  }

  @override
  Future<void> recordDebtPayment({
    required String debtId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    final userId = await _requireDataOwnerUserId();
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
    final userId = await _requireDataOwnerUserId();
    final row = await _client
        .from(table)
        .select('id')
        .eq('id', id)
        .eq('owner_user_id', userId)
        .maybeSingle();
    if (row == null) {
      throw Exception('Data tidak ditemukan.');
    }
  }

  Future<void> _ensureDefaultCategories(String userId) async {
    final rows = await _client
        .from('categories')
        .select('name')
        .eq('owner_user_id', userId)
        .order('name');
    final existingNames = (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((row) => row.stringValue('name'))
        .toSet();
    final missingCategories = _defaultCategories
        .where((category) => !existingNames.contains(category['name']))
        .toList();
    if (missingCategories.isEmpty) {
      return;
    }
    await _client.from('categories').insert(
          missingCategories
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
        .eq('owner_user_id', await _requireDataOwnerUserId())
        .inFilter('id', ids);
    return {
      for (final row in (rows as List<dynamic>).cast<Map<String, dynamic>>())
        row.stringValue('id'): _mapProduct(row),
    };
  }

  Future<Set<String>> _fetchNasiPaketCategoryIds(String userId) async {
    final rows = await _client
        .from('categories')
        .select('id, name')
        .eq('owner_user_id', userId);
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((row) => _isNasiPaketCategoryName(row.stringValue('name')))
        .map((row) => row.stringValue('id'))
        .toSet();
  }

  String _newRecordId(String prefix, DateTime now) {
    final suffix = _idRandom.nextInt(0x3fffffff).toRadixString(36);
    return '$prefix-${now.microsecondsSinceEpoch}-$suffix';
  }

  bool _isNasiPaketCategoryName(String name) {
    final normalized = name.trim().toLowerCase();
    return normalized == 'nasi paket';
  }

  Future<String> _buildTransactionCode(
    DateTime now, {
    required String userId,
    int sequenceOffset = 0,
  }) async {
    final start = DateTime(now.year, now.month, now.day).toIso8601String();
    final end = DateTime(now.year, now.month, now.day + 1).toIso8601String();
    final rows = await _client
        .from('transactions')
        .select('transaction_code')
        .eq('owner_user_id', userId)
        .gte('created_at', start)
        .lt('created_at', end);
    final prefix = _transactionCodeDatePrefix(now);
    final maxSequence =
        (rows as List<dynamic>).cast<Map<String, dynamic>>().fold<int>(
      0,
      (maxSequence, row) {
        final code = row.stringValue('transaction_code');
        if (!code.startsWith('$prefix-')) {
          return maxSequence;
        }
        final sequence = int.tryParse(code.substring(prefix.length + 1));
        if (sequence == null || sequence <= maxSequence) {
          return maxSequence;
        }
        return sequence;
      },
    );
    final sequence = maxSequence + sequenceOffset + 1;
    return '$prefix-${sequence.toString().padLeft(3, '0')}';
  }

  String _transactionCodeDatePrefix(DateTime now) {
    return 'TRX-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  Future<TransactionRecord> _insertTransactionWithRetry({
    required String userId,
    required DateTime now,
    required String? customerId,
    required String customerName,
    required double totalAmount,
    required PaymentMethod paymentMethod,
    required List<TransactionItem> items,
    String? notes,
  }) async {
    final creator = await _currentTransactionCreator();
    for (var attempt = 0; attempt < _transactionInsertMaxAttempts; attempt++) {
      final transaction = TransactionRecord(
        id: _newRecordId('trx', now),
        transactionCode: await _buildTransactionCode(
          now,
          userId: userId,
          sequenceOffset: attempt,
        ),
        customerId: customerId,
        customerName: customerName,
        totalAmount: totalAmount,
        paymentMethod: paymentMethod,
        amountPaid: paymentMethod == PaymentMethod.bon ? 0 : totalAmount,
        changeAmount: 0,
        createdAt: now,
        items: items,
        notes: notes,
        createdByUserId: creator.userId,
        createdByName: creator.name,
      );

      try {
        final values = _transactionValues(transaction, userId);
        await _client.from('transactions').insert(values);
        return transaction;
      } on PostgrestException catch (error) {
        if (_isTransactionCreatorColumnMissing(error)) {
          await _client
              .from('transactions')
              .insert(_transactionValues(transaction, userId, legacy: true));
          return transaction;
        }
        if (!_isDuplicateTransactionCodeError(error) ||
            attempt == _transactionInsertMaxAttempts - 1) {
          rethrow;
        }
      }
    }

    throw StateError('Gagal membuat kode transaksi unik.');
  }

  Map<String, Object?> _transactionValues(
    TransactionRecord transaction,
    String ownerUserId, {
    bool legacy = false,
  }) {
    return {
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
      'owner_user_id': ownerUserId,
      if (!legacy) ...{
        'created_by_user_id': transaction.createdByUserId,
        'created_by_name': transaction.createdByName,
      },
    };
  }

  bool _isDuplicateTransactionCodeError(PostgrestException error) {
    final text = '${error.code} ${error.message} ${error.details}';
    return text.contains('23505') && text.contains('transaction_code');
  }

  Future<_TransactionCreator> _currentTransactionCreator() async {
    final user = _client.auth.currentUser;
    final userId = _requireUserId();

    try {
      final row = await _client
          .from('profiles')
          .select('full_name, email')
          .eq('id', userId)
          .maybeSingle();
      final profile = row == null ? null : Map<String, dynamic>.from(row);
      final name = _firstNonBlank([
        profile?['full_name'] as String?,
        profile?['email'] as String?,
        user?.userMetadata?['full_name'] as String?,
        user?.email,
      ]);
      return _TransactionCreator(userId: userId, name: name ?? userId);
    } on PostgrestException catch (error) {
      if (!_isProfileLookupUnavailable(error)) {
        rethrow;
      }
      final name = _firstNonBlank([
        user?.userMetadata?['full_name'] as String?,
        user?.email,
      ]);
      return _TransactionCreator(userId: userId, name: name ?? userId);
    }
  }

  String? _firstNonBlank(Iterable<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
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
      isReady: row['is_ready'] == null ? true : row.intValue('is_ready') == 1,
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
      'is_ready': product.isReady ? 1 : 0,
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

  Future<String?> _uploadMediaIfNeeded(
    String? mediaPath, {
    required String userId,
    required String folder,
    required String recordId,
  }) async {
    final trimmedPath = mediaPath?.trim();
    if (trimmedPath == null || trimmedPath.isEmpty) {
      return null;
    }
    if (_isRemoteMediaPath(trimmedPath)) {
      return trimmedPath;
    }

    final file = File(trimmedPath);
    if (!await file.exists()) {
      return trimmedPath;
    }

    final extension = _safeImageExtension(trimmedPath);
    final objectPath = [
      userId,
      folder,
      '$recordId-${DateTime.now().microsecondsSinceEpoch}$extension',
    ].join('/');

    await _client.storage.from(_mediaBucket).upload(
          objectPath,
          file,
          fileOptions: FileOptions(
            cacheControl: '31536000',
            contentType: _contentTypeForExtension(extension),
            upsert: true,
          ),
        );

    final publicUrl = _client.storage.from(_mediaBucket).getPublicUrl(
          objectPath,
        );
    await _deleteTemporaryUploadFile(file);
    return publicUrl;
  }

  bool _isRemoteMediaPath(String mediaPath) {
    return mediaPath.startsWith('http://') || mediaPath.startsWith('https://');
  }

  String _safeImageExtension(String mediaPath) {
    final extension = p.extension(mediaPath).toLowerCase();
    return switch (extension) {
      '.jpeg' || '.jpg' || '.png' || '.webp' || '.gif' => extension,
      _ => '.jpg',
    };
  }

  String _contentTypeForExtension(String extension) {
    return switch (extension) {
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      '.gif' => 'image/gif',
      _ => 'image/jpeg',
    };
  }

  Future<void> _deleteTemporaryUploadFile(File file) async {
    if (!p.split(file.path).contains('toko_saku_uploads')) {
      return;
    }
    try {
      await file.delete();
    } catch (_) {
      // Temporary preview cleanup is best effort after a successful upload.
    }
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Sesi login tidak ditemukan. Silakan login ulang.');
    }
    return userId;
  }

  Future<String> _requireDataOwnerUserId() async {
    final userId = _requireUserId();
    if (_cachedAuthUserId == userId && _cachedDataOwnerUserId != null) {
      return _cachedDataOwnerUserId!;
    }

    Map<String, dynamic>? profile;
    try {
      final row = await _client
          .from('profiles')
          .select('store_owner_user_id')
          .eq('id', userId)
          .maybeSingle();
      profile = row == null ? null : Map<String, dynamic>.from(row);
    } on PostgrestException catch (error) {
      if (!_isStoreOwnerColumnMissing(error)) {
        rethrow;
      }
      profile = null;
    }
    final ownerUserId = profile?['store_owner_user_id'] as String? ?? userId;
    _cachedAuthUserId = userId;
    _cachedDataOwnerUserId = ownerUserId;
    return ownerUserId;
  }

  bool _isStoreOwnerColumnMissing(PostgrestException error) {
    final text = '${error.code} ${error.message}';
    return text.contains('42703') || text.contains('store_owner_user_id');
  }

  bool _isTransactionCreatorColumnMissing(PostgrestException error) {
    final text = '${error.code} ${error.message} ${error.details}';
    return text.contains('42703') ||
        text.contains('created_by_user_id') ||
        text.contains('created_by_name');
  }

  bool _isProfileLookupUnavailable(PostgrestException error) {
    final text = '${error.code} ${error.message} ${error.details}';
    return text.contains('42703') ||
        text.contains('profiles') ||
        text.contains('full_name') ||
        text.contains('email');
  }
}

extension on Map<String, dynamic> {
  String stringValue(String key) => this[key] as String;

  int intValue(String key) => (this[key] as num).toInt();

  double doubleValue(String key) => (this[key] as num).toDouble();
}

class _TransactionCreator {
  const _TransactionCreator({
    required this.userId,
    required this.name,
  });

  final String userId;
  final String name;
}
