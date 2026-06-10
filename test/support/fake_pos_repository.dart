import 'dart:math';

import 'package:warung_kopi_pos/shared/data/seed_data.dart';
import 'package:warung_kopi_pos/shared/database/pos_repository.dart';
import 'package:warung_kopi_pos/shared/models/app_models.dart';

class FakePosRepository implements PosRepository {
  FakePosRepository() {
    final seed = buildSeedData();
    _appProfile = seed.appProfile;
    _categories = List.of(seed.categories);
    _products = List.of(seed.products);
    _customers = List.of(seed.customers);
    _transactions = List.of(seed.transactions);
    _debts = List.of(seed.debts);
    _payments = List.of(seed.payments);
    _stockMovements = List.of(seed.stockMovements);
    _operationalCosts = List.of(seed.operationalCosts);
  }

  static final Random _idRandom = Random();

  AppProfile? _appProfile;
  late List<Category> _categories;
  late List<Product> _products;
  late List<Customer> _customers;
  late List<TransactionRecord> _transactions;
  final List<PendingTransaction> _pendingTransactions = [];
  late List<DebtRecord> _debts;
  late List<DebtPayment> _payments;
  late List<StockMovement> _stockMovements;
  late List<OperationalCost> _operationalCosts;

  @override
  Future<AppProfile?> fetchAppProfile() async => _appProfile;

  @override
  Future<List<Category>> fetchCategories() async => List.of(_categories);

  @override
  Future<List<Product>> fetchProducts() async => List.of(_products);

  @override
  Future<List<Customer>> fetchCustomers() async =>
      List.of(_customers)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<List<TransactionRecord>> fetchTransactions() async =>
      List.of(_transactions)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<List<PendingTransaction>> fetchPendingTransactions() async =>
      List.of(_pendingTransactions)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<List<DebtRecord>> fetchDebts() async =>
      List.of(_debts)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<List<DebtPayment>> fetchPayments() async =>
      List.of(_payments)..sort((a, b) => b.paidAt.compareTo(a.paidAt));

  @override
  Future<List<StockMovement>> fetchStockMovements() async =>
      List.of(_stockMovements)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<List<OperationalCost>> fetchOperationalCosts() async =>
      List.of(_operationalCosts)
        ..sort((a, b) => a.monthYear.compareTo(b.monthYear));

  @override
  Future<OperationalCost> saveOperationalCost({
    String? id,
    required DateTime monthYear,
    required String costName,
    required double amount,
  }) async {
    final normalizedMonth = DateTime(monthYear.year, monthYear.month, 1);
    final cost = OperationalCost(
      id: id ?? _newRecordId('opc'),
      monthYear: normalizedMonth,
      costName: costName,
      amount: amount,
    );
    if (id == null) {
      _operationalCosts.add(cost);
    } else {
      final index = _operationalCosts.indexWhere((item) => item.id == id);
      if (index == -1) {
        throw Exception('Biaya operasional tidak ditemukan.');
      }
      _operationalCosts[index] = cost;
    }
    return cost;
  }

  @override
  Future<void> deleteOperationalCost(String id) async {
    final beforeLength = _operationalCosts.length;
    _operationalCosts.removeWhere((item) => item.id == id);
    if (_operationalCosts.length == beforeLength) {
      throw Exception('Biaya operasional tidak ditemukan.');
    }
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
    if (id == null) {
      final customer = Customer(
        id: _newRecordId('cus'),
        name: name,
        phone: phone,
        address: address,
        notes: notes,
        isActive: isActive,
        createdAt: DateTime.now(),
      );
      _customers.add(customer);
      return customer;
    }

    final index = _customers.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw Exception('Pelanggan tidak ditemukan.');
    }
    final customer = _customers[index].copyWith(
      name: name,
      phone: phone,
      address: address,
      notes: notes,
      isActive: isActive,
    );
    _customers[index] = customer;
    return customer;
  }

  @override
  Future<AppProfile> saveAppProfile({
    required String storeName,
    required String storeSubtitle,
    String? ownerName,
    String? photoPath,
  }) async {
    final profile = AppProfile(
      id: _appProfile?.id ?? 'store-main',
      storeName: storeName,
      storeSubtitle: storeSubtitle,
      ownerName: ownerName,
      photoPath: photoPath,
    );
    _appProfile = profile;
    return profile;
  }

  @override
  Future<void> toggleCustomerActive(String customerId) async {
    final index = _customers.indexWhere((item) => item.id == customerId);
    if (index == -1) {
      throw Exception('Pelanggan tidak ditemukan.');
    }
    final customer = _customers[index];
    _customers[index] = customer.copyWith(isActive: !customer.isActive);
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
    if (id == null) {
      _products.add(
        Product(
          id: _newRecordId('prd'),
          name: name,
          categoryId: categoryId,
          sellPrice: sellPrice,
          costPrice: costPrice,
          stockQty: stockQty,
          minStock: minStock,
          unit: unit,
          rackLocation: rackLocation,
          imagePath: imagePath,
          isReady: isReady,
        ),
      );
      return;
    }

    final index = _products.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw Exception('Produk tidak ditemukan.');
    }
    final preserved = _products[index];
    _products[index] = Product(
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
      isReady: isReady,
    );
  }

  @override
  Future<void> deleteProduct(String productId) async {
    if (!_products.any((item) => item.id == productId)) {
      throw Exception('Produk tidak ditemukan.');
    }
    final usedInTransaction = _transactions.any(
      (transaction) =>
          transaction.items.any((item) => item.productId == productId),
    );
    if (usedInTransaction) {
      throw Exception(
        'Produk sudah dipakai di transaksi dan tidak bisa dihapus.',
      );
    }
    _products.removeWhere((item) => item.id == productId);
  }

  @override
  Future<TransactionRecord> checkout({
    required Map<String, int> cart,
    required String? customerId,
    required String customerName,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    final now = DateTime.now();
    final items = _buildTransactionItems(cart);
    _validateStock(items);
    final transaction = _createTransaction(
      items: items,
      customerId: customerId,
      customerName: customerName,
      paymentMethod: paymentMethod,
      notes: notes,
      now: now,
    );
    _transactions.add(transaction);
    _cutStockAndRecordMovements(items, transaction.transactionCode, now);
    _createDebtIfNeeded(transaction);
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
    final now = DateTime.now();
    final items = _buildPendingItems(cart);
    final pending = PendingTransaction(
      id: _newRecordId('tmp'),
      customerId: customerId,
      customerName: customerName,
      totalAmount: items.fold(0.0, (sum, item) => sum + item.subtotal),
      createdAt: now,
      items: items,
      notes: notes,
    );
    _pendingTransactions.add(pending);
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
    final index = _pendingTransactions.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw Exception('Transaksi berlangsung tidak ditemukan.');
    }
    final existing = _pendingTransactions[index];
    final items = _buildPendingItems(cart);
    final pending = PendingTransaction(
      id: id,
      customerId: customerId,
      customerName: customerName,
      totalAmount: items.fold(0.0, (sum, item) => sum + item.subtotal),
      createdAt: existing.createdAt,
      items: items,
      notes: notes,
    );
    _pendingTransactions[index] = pending;
    return pending;
  }

  @override
  Future<TransactionRecord> checkoutPendingTransaction({
    required String pendingTransactionId,
    required PaymentMethod paymentMethod,
  }) async {
    final index = _pendingTransactions.indexWhere(
      (item) => item.id == pendingTransactionId,
    );
    if (index == -1) {
      throw Exception('Transaksi berlangsung tidak ditemukan.');
    }
    final pending = _pendingTransactions[index];
    if (pending.items.isEmpty) {
      throw Exception('Transaksi berlangsung belum memiliki item.');
    }
    final now = DateTime.now();
    final items = pending.items
        .map(
          (item) => TransactionItem(
            productId: item.productId,
            productName: item.productName,
            quantity: item.quantity,
            sellPrice: item.sellPrice,
          ),
        )
        .toList();
    _validateStock(items);
    final transaction = _createTransaction(
      items: items,
      customerId: pending.customerId,
      customerName: pending.customerName,
      paymentMethod: paymentMethod,
      notes: pending.notes,
      now: now,
    );
    _transactions.add(transaction);
    _cutStockAndRecordMovements(items, transaction.transactionCode, now);
    _createDebtIfNeeded(transaction);
    _pendingTransactions.removeAt(index);
    return transaction;
  }

  @override
  Future<void> recordDebtPayment({
    required String debtId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    final index = _debts.indexWhere((item) => item.id == debtId);
    if (index == -1) {
      throw Exception('Utang tidak ditemukan.');
    }
    final debt = _debts[index];
    final remainingAmount = max(0.0, debt.remainingAmount);
    if (amount <= 0) {
      throw Exception('Nominal pembayaran harus lebih dari 0.');
    }
    if (amount > remainingAmount) {
      throw Exception('Nominal pembayaran melebihi sisa utang.');
    }
    final now = DateTime.now();
    _debts[index] = debt.copyWith(
      paidAmount: debt.paidAmount + amount,
      updatedAt: now,
    );
    _payments.add(
      DebtPayment(
        id: _newRecordId('pay'),
        debtId: debtId,
        customerId: debt.customerId,
        amount: amount,
        paymentMethod: paymentMethod,
        paidAt: now,
        notes: notes,
      ),
    );
  }

  List<TransactionItem> _buildTransactionItems(Map<String, int> cart) {
    return cart.entries.map((entry) {
      final product = _productById(entry.key);
      final quantity = entry.value;
      if (quantity <= 0) {
        throw Exception('Jumlah produk harus lebih dari 0.');
      }
      return TransactionItem(
        productId: product.id,
        productName: product.name,
        quantity: quantity,
        sellPrice: product.sellPrice,
      );
    }).toList();
  }

  List<PendingTransactionItem> _buildPendingItems(Map<String, int> cart) {
    return cart.entries.map((entry) {
      final product = _productById(entry.key);
      final quantity = entry.value;
      if (quantity <= 0) {
        throw Exception('Jumlah produk harus lebih dari 0.');
      }
      return PendingTransactionItem(
        productId: product.id,
        productName: product.name,
        quantity: quantity,
        sellPrice: product.sellPrice,
      );
    }).toList();
  }

  TransactionRecord _createTransaction({
    required List<TransactionItem> items,
    required String? customerId,
    required String customerName,
    required PaymentMethod paymentMethod,
    required String? notes,
    required DateTime now,
  }) {
    final sequence = _transactions.where((transaction) {
          return transaction.createdAt.year == now.year &&
              transaction.createdAt.month == now.month &&
              transaction.createdAt.day == now.day;
        }).length +
        1;
    final transactionCode =
        'TRX-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${sequence.toString().padLeft(3, '0')}';
    final totalAmount = items.fold(0.0, (sum, item) => sum + item.subtotal);
    return TransactionRecord(
      id: _newRecordId('trx'),
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
  }

  void _validateStock(List<TransactionItem> items) {
    for (final item in items) {
      final product = _productById(item.productId);
      if (!_isNasiPaketProduct(product) && item.quantity > product.stockQty) {
        throw Exception(
          'Stok ${item.productName} tidak cukup. Sisa stok ${product.stockQty}.',
        );
      }
    }
  }

  void _cutStockAndRecordMovements(
    List<TransactionItem> items,
    String transactionCode,
    DateTime now,
  ) {
    for (final item in items) {
      final index =
          _products.indexWhere((product) => product.id == item.productId);
      final product = _products[index];
      if (_isNasiPaketProduct(product)) {
        continue;
      }
      _products[index] = product.copyWith(
        stockQty: max(0, product.stockQty - item.quantity),
      );
      _stockMovements.add(
        StockMovement(
          id: _newRecordId('stm'),
          productId: item.productId,
          referenceName: item.productName,
          quantity: item.quantity.toDouble(),
          type: StockMovementType.stockOut,
          createdAt: now,
          notes: 'Transaksi $transactionCode',
        ),
      );
    }
  }

  void _createDebtIfNeeded(TransactionRecord transaction) {
    final customerId = transaction.customerId;
    if (transaction.paymentMethod != PaymentMethod.bon || customerId == null) {
      return;
    }
    _debts.add(
      DebtRecord(
        id: _newRecordId('debt'),
        transactionId: transaction.id,
        customerId: customerId,
        customerName: transaction.customerName,
        originalAmount: transaction.totalAmount,
        paidAmount: 0,
        createdAt: transaction.createdAt,
        updatedAt: transaction.createdAt,
        dueDate: transaction.createdAt.add(const Duration(days: 7)),
        notes: 'BON - Belum Lunas',
      ),
    );
  }

  Product _productById(String id) {
    return _products.firstWhere(
      (product) => product.id == id,
      orElse: () => throw Exception('Produk tidak ditemukan.'),
    );
  }

  bool _isNasiPaketProduct(Product product) {
    final category = _categories.firstWhere(
      (item) => item.id == product.categoryId,
      orElse: () => const Category(id: '', name: ''),
    );
    return category.name.trim().toLowerCase() == 'nasi paket';
  }

  String _newRecordId(String prefix) {
    final now = DateTime.now();
    final suffix = _idRandom.nextInt(0x3fffffff).toRadixString(36);
    return '$prefix-${now.microsecondsSinceEpoch}-$suffix';
  }
}
