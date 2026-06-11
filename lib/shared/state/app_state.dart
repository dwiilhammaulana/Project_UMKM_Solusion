import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/pos_repository.dart';
import '../database/supabase_pos_repository.dart';
import '../models/app_models.dart';
import '../supabase/supabase_providers.dart';

final posRepositoryProvider = Provider<PosRepository>((ref) {
  return SupabasePosRepository(ref.watch(supabaseClientProvider));
});

final posStateProvider = ChangeNotifierProvider<PosAppState>((ref) {
  return PosAppState(repository: ref.watch(posRepositoryProvider));
});

class PosAppState extends ChangeNotifier {
  PosAppState({required PosRepository repository}) : _repository = repository {
    unawaited(initialize());
  }

  final PosRepository _repository;
  static const _fallbackProfile = AppProfile(
    id: 'store-main',
    storeName: 'Warung Kopi',
    storeSubtitle: 'Lengkapi profil toko untuk mulai memakai aplikasi.',
  );

  AppProfile? _appProfile;
  List<Category> _categories = const [];
  List<Product> _products = const [];
  List<Customer> _customers = const [];
  List<TransactionRecord> _transactions = const [];
  List<PendingTransaction> _pendingTransactions = const [];
  List<DebtRecord> _debts = const [];
  List<DebtPayment> _payments = const [];
  List<StockMovement> _stockMovements = const [];
  List<OperationalCost> _operationalCosts = const [];
  Map<String, Category> _categoryById = const {};
  Map<String, Product> _productById = const {};
  Map<String, Customer> _customerById = const {};
  List<Product> _cartProducts = const [];
  int _cartCount = 0;
  double _cartTotal = 0;
  late final Map<String, int> _cartView = UnmodifiableMapView(_cart);
  List<DebtRecord> _activeDebtsSorted = const [];
  List<Product> _lowStockProducts = const [];
  Map<int, List<OperationalCost>> _operationalCostsByMonth = const {};
  Map<int, double> _operationalCostTotalByMonth = const {};
  Map<String, List<TransactionRecord>> _transactionsByCustomer = const {};
  Map<String, List<DebtRecord>> _debtsByCustomer = const {};
  Map<String, List<DebtPayment>> _paymentsByCustomer = const {};
  Map<String, double> _totalPurchaseByCustomer = const {};
  Map<String, double> _activeDebtByCustomer = const {};
  double _totalRevenue = 0;
  double _activeDebtTotal = 0;
  double _totalOperationalCost = 0;
  List<ReportSummary> _reportSummaries = const [];
  DateTime? _reportSummaryMonth;

  final Map<String, int> _cart = {};
  String? _selectedCustomerId;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  bool _isLoading = true;
  String? _errorMessage;

  AppProfile get appProfile => _appProfile ?? _fallbackProfile;
  bool get hasAppProfile => _appProfile != null;
  List<Category> get categories => _categories;
  List<Product> get products => _products;
  List<Customer> get customers => _customers;
  List<TransactionRecord> get transactions => _transactions;
  List<PendingTransaction> get pendingTransactions => _pendingTransactions;
  List<DebtRecord> get debts => _debts;
  List<DebtPayment> get payments => _payments;
  List<StockMovement> get stockMovements => _stockMovements;
  List<OperationalCost> get operationalCosts => _operationalCosts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Product? productById(String productId) => _productById[productId];
  Customer? customerById(String customerId) => _customerById[customerId];
  String categoryNameById(String categoryId) {
    return _categoryById[categoryId]?.name ?? 'Tanpa kategori';
  }

  Map<String, int> get cart => _cartView;
  String? get selectedCustomerId => _selectedCustomerId;
  PaymentMethod get selectedPaymentMethod => _selectedPaymentMethod;
  Customer? get selectedCustomer {
    final selectedId = _selectedCustomerId;
    return selectedId == null ? null : _customerById[selectedId];
  }

  List<Product> get cartProducts => _cartProducts;

  double get cartTotal => _cartTotal;

  int get cartCount => _cartCount;

  bool get cartContainsNasiPaket =>
      _cartProducts.any((product) => isNasiPaketProduct(product));

  List<DebtRecord> get activeDebtsSorted => _activeDebtsSorted;

  List<Product> get lowStockProducts => _lowStockProducts;

  double get totalRevenue => _totalRevenue;

  double get activeDebtTotal => _activeDebtTotal;

  double get totalOperationalCost => _totalOperationalCost;

  List<OperationalCost> operationalCostsByMonth(DateTime monthYear) {
    return _operationalCostsByMonth[_monthKey(monthYear)] ?? const [];
  }

  double operationalCostTotalByMonth(DateTime monthYear) {
    return _operationalCostTotalByMonth[_monthKey(monthYear)] ?? 0.0;
  }

  int get todayTransactionCount {
    final now = DateTime.now();
    return _transactions
        .where(
          (trx) =>
              trx.createdAt.year == now.year &&
              trx.createdAt.month == now.month &&
              trx.createdAt.day == now.day,
        )
        .length;
  }

  List<ReportSummary> get reportSummaries {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    if (_reportSummaryMonth != currentMonth) {
      _rebuildReportSummaries(now);
    }
    return _reportSummaries;
  }

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reloadPersistedData();
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _errorMessage = error.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reload() => initialize();

  void addToCart(Product product) {
    _ensureProductCanBeAdded(product);
    final nextQty = (_cart[product.id] ?? 0) + 1;
    _ensureCartQtyWithinStock(product.id, nextQty);
    _cart[product.id] = nextQty;
    _rebuildCartDerivedData();
    notifyListeners();
  }

  void increaseCartQty(String productId) {
    final current = _cart[productId];
    if (current == null) {
      return;
    }
    final nextQty = current + 1;
    _ensureCartQtyWithinStock(productId, nextQty);
    _cart[productId] = nextQty;
    _rebuildCartDerivedData();
    notifyListeners();
  }

  void decreaseCartQty(String productId) {
    final current = _cart[productId];
    if (current == null) {
      return;
    }
    if (current <= 1) {
      _cart.remove(productId);
    } else {
      _cart[productId] = current - 1;
    }
    _rebuildCartDerivedData();
    notifyListeners();
  }

  void removeFromCart(String productId) {
    if (!_cart.containsKey(productId)) {
      return;
    }
    _cart.remove(productId);
    _rebuildCartDerivedData();
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _rebuildCartDerivedData();
    notifyListeners();
  }

  void setSelectedCustomer(String? customerId) {
    _selectedCustomerId = customerId;
    notifyListeners();
  }

  void setPaymentMethod(PaymentMethod method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  Future<Customer> saveCustomer({
    String? id,
    required String name,
    required String phone,
    required String address,
    String? notes,
    bool isActive = true,
  }) async {
    final customer = await _repository.saveCustomer(
      id: id,
      name: name,
      phone: phone,
      address: address,
      notes: notes,
      isActive: isActive,
    );
    await _reloadPersistedData();
    notifyListeners();
    return customer;
  }

  Future<AppProfile> saveAppProfile({
    required String storeName,
    required String storeSubtitle,
    String? ownerName,
    String? photoPath,
  }) async {
    final profile = await _repository.saveAppProfile(
      storeName: storeName,
      storeSubtitle: storeSubtitle,
      ownerName: ownerName,
      photoPath: photoPath,
    );
    await _reloadPersistedData();
    notifyListeners();
    return profile;
  }

  Future<void> toggleCustomerActive(String customerId) async {
    await _repository.toggleCustomerActive(customerId);
    await _reloadPersistedData();
    notifyListeners();
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
    bool isReady = true,
  }) async {
    final isNasiPaket = isNasiPaketCategory(categoryId);
    await _repository.saveProduct(
      id: id,
      name: name,
      categoryId: categoryId,
      sellPrice: sellPrice,
      costPrice: costPrice,
      stockQty: isNasiPaket ? 0 : stockQty,
      minStock: isNasiPaket ? 0 : minStock,
      unit: unit,
      rackLocation: rackLocation,
      imagePath: imagePath,
      isReady: isReady,
    );
    await _reloadPersistedData();
    notifyListeners();
  }

  Future<void> deleteProduct(String productId) async {
    await _repository.deleteProduct(productId);
    _cart.remove(productId);
    await _reloadPersistedData();
    notifyListeners();
  }

  Future<void> saveOperationalCost({
    String? id,
    required DateTime monthYear,
    required String costName,
    required double amount,
  }) async {
    await _repository.saveOperationalCost(
      id: id,
      monthYear: monthYear,
      costName: costName,
      amount: amount,
    );
    await _reloadPersistedData();
    notifyListeners();
  }

  Future<void> deleteOperationalCost(String id) async {
    await _repository.deleteOperationalCost(id);
    await _reloadPersistedData();
    notifyListeners();
  }

  Future<TransactionRecord> checkout({String? notes}) async {
    if (_cart.isEmpty) {
      throw Exception('Keranjang masih kosong.');
    }
    if (_selectedPaymentMethod == PaymentMethod.bon &&
        _selectedCustomerId == null) {
      throw Exception('Transaksi BON wajib memilih pelanggan terdaftar.');
    }

    final transaction = await _repository.checkout(
      cart: _cart,
      customerId: _selectedCustomerId,
      customerName: selectedCustomer?.name ?? 'Umum / Tanpa Nama',
      paymentMethod: _selectedPaymentMethod,
      notes: notes,
    );

    await _reloadPersistedData();
    _cart.clear();
    _selectedCustomerId = null;
    _selectedPaymentMethod = PaymentMethod.cash;
    _rebuildCartDerivedData();
    notifyListeners();
    return transaction;
  }

  Future<PendingTransaction> moveCartToPendingTransaction({
    String? notes,
  }) async {
    if (_cart.isEmpty) {
      throw Exception('Keranjang masih kosong.');
    }
    if (!cartContainsNasiPaket) {
      throw Exception(
        'Transaksi sementara hanya untuk pesanan kategori nasi paket.',
      );
    }

    final pending = await _repository.savePendingTransactionFromCart(
      cart: _cart,
      customerId: _selectedCustomerId,
      customerName: selectedCustomer?.name ?? 'Umum / Tanpa Nama',
      notes: notes,
    );

    await _reloadPersistedData();
    _cart.clear();
    _selectedCustomerId = null;
    _selectedPaymentMethod = PaymentMethod.cash;
    _rebuildCartDerivedData();
    notifyListeners();
    return pending;
  }

  Future<void> addProductToPendingTransaction({
    required String pendingTransactionId,
    required Product product,
  }) async {
    final pending = _requirePendingTransaction(pendingTransactionId);
    _ensureProductCanBeAdded(product);
    final cart = _pendingCart(pending);
    final nextQty = (cart[product.id] ?? 0) + 1;
    _ensureCartQtyWithinStock(product.id, nextQty);
    cart[product.id] = nextQty;
    await _savePendingTransaction(pending, cart: cart);
  }

  Future<void> increasePendingTransactionQty({
    required String pendingTransactionId,
    required String productId,
  }) async {
    final pending = _requirePendingTransaction(pendingTransactionId);
    final product = _productById[productId];
    if (product == null) {
      throw Exception('Produk tidak ditemukan.');
    }
    _ensureProductCanBeAdded(product);
    final cart = _pendingCart(pending);
    final current = cart[productId];
    if (current == null) {
      return;
    }
    final nextQty = current + 1;
    _ensureCartQtyWithinStock(productId, nextQty);
    cart[productId] = nextQty;
    await _savePendingTransaction(pending, cart: cart);
  }

  Future<void> decreasePendingTransactionQty({
    required String pendingTransactionId,
    required String productId,
  }) async {
    final pending = _requirePendingTransaction(pendingTransactionId);
    final cart = _pendingCart(pending);
    final current = cart[productId];
    if (current == null) {
      return;
    }
    if (current <= 1) {
      if (cart.length <= 1) {
        throw Exception(
          'Transaksi berlangsung harus memiliki minimal satu produk.',
        );
      }
      cart.remove(productId);
    } else {
      cart[productId] = current - 1;
    }
    await _savePendingTransaction(pending, cart: cart);
  }

  Future<void> removePendingTransactionItem({
    required String pendingTransactionId,
    required String productId,
  }) async {
    final pending = _requirePendingTransaction(pendingTransactionId);
    final cart = _pendingCart(pending);
    if (!cart.containsKey(productId)) {
      return;
    }
    if (cart.length <= 1) {
      throw Exception(
        'Transaksi berlangsung harus memiliki minimal satu produk.',
      );
    }
    cart.remove(productId);
    await _savePendingTransaction(pending, cart: cart);
  }

  Future<void> setPendingTransactionCustomer({
    required String pendingTransactionId,
    required String? customerId,
  }) async {
    final pending = _requirePendingTransaction(pendingTransactionId);
    final customer = customerId == null ? null : _customerById[customerId];
    if (customerId != null && customer == null) {
      throw Exception('Pelanggan tidak ditemukan.');
    }
    await _savePendingTransaction(
      pending,
      cart: _pendingCart(pending),
      updateCustomer: true,
      customerId: customerId,
      customerName: customer?.name ?? 'Umum / Tanpa Nama',
    );
  }

  Future<TransactionRecord> checkoutPendingTransaction({
    required String pendingTransactionId,
    required PaymentMethod paymentMethod,
  }) async {
    final pending = pendingTransactionById(pendingTransactionId);
    if (pending == null) {
      throw Exception('Transaksi berlangsung tidak ditemukan.');
    }
    if (paymentMethod == PaymentMethod.bon && pending.customerId == null) {
      throw Exception('Transaksi BON wajib memilih pelanggan terdaftar.');
    }

    final transaction = await _repository.checkoutPendingTransaction(
      pendingTransactionId: pendingTransactionId,
      paymentMethod: paymentMethod,
    );
    await _reloadPersistedData();
    notifyListeners();
    return transaction;
  }

  Future<void> recordDebtPayment({
    required String debtId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    await _repository.recordDebtPayment(
      debtId: debtId,
      amount: amount,
      paymentMethod: paymentMethod,
      notes: notes,
    );
    await _reloadPersistedData();
    notifyListeners();
  }

  Future<void> markDebtPaid(String debtId) async {
    final debt = _debts.firstWhere((item) => item.id == debtId);
    final remaining = debt.remainingAmount;
    if (remaining <= 0) {
      return;
    }
    await recordDebtPayment(
      debtId: debtId,
      amount: remaining,
      paymentMethod: PaymentMethod.cash,
      notes: 'Pelunasan cepat dari tombol dashboard',
    );
  }

  List<TransactionRecord> transactionsByCustomer(String customerId) {
    return _transactionsByCustomer[customerId] ?? const [];
  }

  TransactionRecord? transactionById(String id) {
    for (final transaction in _transactions) {
      if (transaction.id == id) {
        return transaction;
      }
    }
    return null;
  }

  PendingTransaction? pendingTransactionById(String id) {
    for (final transaction in _pendingTransactions) {
      if (transaction.id == id) {
        return transaction;
      }
    }
    return null;
  }

  PendingTransaction _requirePendingTransaction(String id) {
    final pending = pendingTransactionById(id);
    if (pending == null) {
      throw Exception('Transaksi berlangsung tidak ditemukan.');
    }
    return pending;
  }

  Map<String, int> _pendingCart(PendingTransaction pending) {
    return {
      for (final item in pending.items) item.productId: item.quantity,
    };
  }

  Future<void> _savePendingTransaction(
    PendingTransaction pending, {
    required Map<String, int> cart,
    bool updateCustomer = false,
    String? customerId,
    String? customerName,
  }) async {
    await _repository.updatePendingTransaction(
      id: pending.id,
      cart: cart,
      customerId: updateCustomer ? customerId : pending.customerId,
      customerName: updateCustomer
          ? (customerName ?? 'Umum / Tanpa Nama')
          : pending.customerName,
      notes: pending.notes,
    );
    await _reloadPersistedData();
    notifyListeners();
  }

  bool isNasiPaketCategory(String categoryId) {
    return _isNasiPaketCategoryName(_categoryById[categoryId]?.name);
  }

  bool isNasiPaketProduct(Product product) {
    return isNasiPaketCategory(product.categoryId);
  }

  bool _isNasiPaketCategoryName(String? name) {
    final normalized = name?.trim().toLowerCase();
    return normalized == 'nasi paket';
  }

  List<DebtRecord> debtsByCustomer(String customerId) {
    return _debtsByCustomer[customerId] ?? const [];
  }

  List<DebtPayment> paymentsByCustomer(String customerId) {
    return _paymentsByCustomer[customerId] ?? const [];
  }

  double totalPurchaseByCustomer(String customerId) {
    return _totalPurchaseByCustomer[customerId] ?? 0.0;
  }

  double activeDebtByCustomer(String customerId) {
    return _activeDebtByCustomer[customerId] ?? 0.0;
  }

  Future<void> _reloadPersistedData() async {
    final results = await Future.wait<dynamic>([
      _repository.fetchAppProfile(),
      _repository.fetchCategories(),
      _repository.fetchProducts(),
      _repository.fetchCustomers(),
      _repository.fetchTransactions(),
      _repository.fetchPendingTransactions(),
      _repository.fetchDebts(),
      _repository.fetchPayments(),
      _repository.fetchStockMovements(),
      _repository.fetchOperationalCosts(),
    ]);

    _appProfile = results[0] as AppProfile?;
    _categories = results[1] as List<Category>;
    _products = results[2] as List<Product>;
    _customers = results[3] as List<Customer>;
    _transactions = results[4] as List<TransactionRecord>;
    _pendingTransactions = results[5] as List<PendingTransaction>;
    _debts = results[6] as List<DebtRecord>;
    _payments = results[7] as List<DebtPayment>;
    _stockMovements = results[8] as List<StockMovement>;
    _operationalCosts = results[9] as List<OperationalCost>;
    _rebuildDerivedData();
    _selectedCustomerId =
        _customers.any((item) => item.id == _selectedCustomerId)
            ? _selectedCustomerId
            : null;
  }

  void _ensureCartQtyWithinStock(String productId, int requestedQty) {
    final product = _productById[productId];
    if (product == null) {
      throw Exception('Produk tidak ditemukan.');
    }
    if (isNasiPaketProduct(product)) {
      return;
    }
    if (requestedQty > product.stockQty) {
      throw Exception(
        'Stok ${product.name} tidak cukup. Sisa stok ${product.stockQty}.',
      );
    }
  }

  void _ensureProductCanBeAdded(Product product) {
    if (isNasiPaketProduct(product) && !product.isReady) {
      throw Exception('${product.name} sedang kosong.');
    }
  }

  void _rebuildDerivedData() {
    _categoryById = {for (final category in _categories) category.id: category};
    _productById = {for (final product in _products) product.id: product};
    _customerById = {for (final customer in _customers) customer.id: customer};

    _activeDebtsSorted = _debts
        .where((debt) => debt.status != DebtStatus.paid)
        .toList()
      ..sort((a, b) => b.ageInDays.compareTo(a.ageInDays));
    _lowStockProducts = _products
        .where((product) => !isNasiPaketProduct(product) && product.isLowStock)
        .toList()
      ..sort((a, b) => a.stockQty.compareTo(b.stockQty));
    _totalRevenue =
        _transactions.fold(0.0, (sum, trx) => sum + trx.amountPaid) +
            _payments.fold(0.0, (sum, payment) => sum + payment.amount);
    _activeDebtTotal =
        _debts.fold(0.0, (sum, debt) => sum + max(0, debt.remainingAmount));
    _totalOperationalCost =
        _operationalCosts.fold(0.0, (sum, cost) => sum + cost.amount);
    _rebuildOperationalCostIndexes();
    _rebuildCustomerIndexes();
    _rebuildReportSummaries(DateTime.now());
    _rebuildCartDerivedData();
  }

  void _rebuildCartDerivedData() {
    var count = 0;
    var total = 0.0;
    final products = <Product>[];

    for (final entry in _cart.entries) {
      final product = _productById[entry.key];
      if (product == null) {
        continue;
      }
      count += entry.value;
      total += product.sellPrice * entry.value;
      products.add(product);
    }

    _cartCount = count;
    _cartTotal = total;
    _cartProducts = products;
  }

  void _rebuildOperationalCostIndexes() {
    final byMonth = <int, List<OperationalCost>>{};
    final totalsByMonth = <int, double>{};

    for (final cost in _operationalCosts) {
      final key = _monthKey(cost.monthYear);
      (byMonth[key] ??= []).add(cost);
      totalsByMonth[key] = (totalsByMonth[key] ?? 0) + cost.amount;
    }

    for (final entries in byMonth.values) {
      entries.sort((a, b) => a.costName.compareTo(b.costName));
    }

    _operationalCostsByMonth = byMonth;
    _operationalCostTotalByMonth = totalsByMonth;
  }

  void _rebuildCustomerIndexes() {
    final transactionsByCustomer = <String, List<TransactionRecord>>{};
    final debtsByCustomer = <String, List<DebtRecord>>{};
    final paymentsByCustomer = <String, List<DebtPayment>>{};
    final totalPurchaseByCustomer = <String, double>{};
    final activeDebtByCustomer = <String, double>{};

    for (final transaction in _transactions) {
      final customerId = transaction.customerId;
      if (customerId == null) {
        continue;
      }
      (transactionsByCustomer[customerId] ??= []).add(transaction);
      totalPurchaseByCustomer[customerId] =
          (totalPurchaseByCustomer[customerId] ?? 0) + transaction.totalAmount;
    }

    for (final debt in _debts) {
      (debtsByCustomer[debt.customerId] ??= []).add(debt);
      activeDebtByCustomer[debt.customerId] =
          (activeDebtByCustomer[debt.customerId] ?? 0) +
              max(0, debt.remainingAmount);
    }

    for (final payment in _payments) {
      (paymentsByCustomer[payment.customerId] ??= []).add(payment);
    }

    for (final transactions in transactionsByCustomer.values) {
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    for (final debts in debtsByCustomer.values) {
      debts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    for (final payments in paymentsByCustomer.values) {
      payments.sort((a, b) => b.paidAt.compareTo(a.paidAt));
    }

    _transactionsByCustomer = transactionsByCustomer;
    _debtsByCustomer = debtsByCustomer;
    _paymentsByCustomer = paymentsByCustomer;
    _totalPurchaseByCustomer = totalPurchaseByCustomer;
    _activeDebtByCustomer = activeDebtByCustomer;
  }

  void _rebuildReportSummaries(DateTime now) {
    final monthFormatter = DateFormat('MMM', 'id_ID');
    final productCostById = {
      for (final product in _products) product.id: product.costPrice,
    };

    _reportSummaryMonth = DateTime(now.year, now.month, 1);
    _reportSummaries = List.generate(6, (index) {
      final month = DateTime(now.year, now.month - 5 + index, 1);
      final nextMonth = DateTime(month.year, month.month + 1, 1);

      final transactions = _transactions.where(
        (transaction) =>
            !transaction.createdAt.isBefore(month) &&
            transaction.createdAt.isBefore(nextMonth),
      );
      final payments = _payments.where(
        (payment) =>
            !payment.paidAt.isBefore(month) &&
            payment.paidAt.isBefore(nextMonth),
      );
      final revenue =
          transactions.fold(0.0, (sum, trx) => sum + trx.amountPaid) +
              payments.fold(0.0, (sum, payment) => sum + payment.amount);
      final cost = transactions.fold(0.0, (sum, transaction) {
        return sum +
            transaction.items.fold(0.0, (itemSum, item) {
              return itemSum +
                  ((productCostById[item.productId] ?? 0) * item.quantity);
            });
      });
      final activeDebtForMonth =
          month.year == now.year && month.month == now.month
              ? _activeDebtTotal
              : 0.0;
      final rawLabel = monthFormatter.format(month);
      final label = rawLabel.isEmpty
          ? ''
          : '${rawLabel[0].toUpperCase()}${rawLabel.substring(1)}';

      return ReportSummary(
        label: label,
        period: month,
        revenue: revenue,
        cost: cost,
        operationalCost: _operationalCostTotalByMonth[_monthKey(month)] ?? 0,
        activeDebtTotal: activeDebtForMonth,
      );
    });
  }

  int _monthKey(DateTime date) => date.year * 12 + date.month;
}
