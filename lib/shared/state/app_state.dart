import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/app_database.dart';
import '../database/pos_repository.dart';
import '../models/app_models.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final posRepositoryProvider = Provider<PosRepository>((ref) {
  return PosRepository(ref.watch(appDatabaseProvider));
});

final posStateProvider = ChangeNotifierProvider<PosAppState>((ref) {
  return PosAppState(repository: ref.watch(posRepositoryProvider));
});

class PosAppState extends ChangeNotifier {
  PosAppState({required PosRepository repository}) : _repository = repository {
    unawaited(initialize());
  }

  final PosRepository _repository;

  AppProfile _appProfile = const AppProfile(
    id: 'store-main',
    storeName: 'Warung Kopi Pertigaan Jati',
    storeSubtitle: 'Pantau penjualan, stok, dan bon dalam satu aplikasi.',
    ownerName: 'Pemilik Toko',
  );
  List<Category> _categories = const [];
  List<Product> _products = const [];
  List<Customer> _customers = const [];
  List<TransactionRecord> _transactions = const [];
  List<DebtRecord> _debts = const [];
  List<DebtPayment> _payments = const [];
  List<StockMovement> _stockMovements = const [];
  List<OperationalCost> _operationalCosts = const [];

  final Map<String, int> _cart = {};
  String? _selectedCustomerId;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  bool _isLoading = true;
  String? _errorMessage;

  AppProfile get appProfile => _appProfile;
  List<Category> get categories => _categories;
  List<Product> get products => _products;
  List<Customer> get customers => _customers;
  List<TransactionRecord> get transactions => _transactions;
  List<DebtRecord> get debts => _debts;
  List<DebtPayment> get payments => _payments;
  List<StockMovement> get stockMovements => _stockMovements;
  List<OperationalCost> get operationalCosts => _operationalCosts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Map<String, int> get cart => Map.unmodifiable(_cart);
  String? get selectedCustomerId => _selectedCustomerId;
  PaymentMethod get selectedPaymentMethod => _selectedPaymentMethod;
  Customer? get selectedCustomer {
    final selectedId = _selectedCustomerId;
    if (selectedId == null) {
      return null;
    }
    for (final customer in _customers) {
      if (customer.id == selectedId) {
        return customer;
      }
    }
    return null;
  }

  List<Product> get cartProducts => _cart.entries
      .map(
        (entry) => _products.firstWhere((product) => product.id == entry.key),
      )
      .toList();

  double get cartTotal => _cart.entries.fold(0.0, (sum, entry) {
        final product =
            _products.firstWhere((product) => product.id == entry.key);
        return sum + (product.sellPrice * entry.value);
      });

  int get cartCount => _cart.values.fold(0, (sum, value) => sum + value);

  List<DebtRecord> get activeDebtsSorted {
    final result =
        _debts.where((debt) => debt.status != DebtStatus.paid).toList();
    result.sort((a, b) => b.ageInDays.compareTo(a.ageInDays));
    return result;
  }

  List<Product> get lowStockProducts {
    final result = _products.where((product) => product.isLowStock).toList();
    result.sort((a, b) => a.stockQty.compareTo(b.stockQty));
    return result;
  }

  double get totalRevenue =>
      _transactions.fold(0.0, (sum, trx) => sum + trx.amountPaid) +
      _payments.fold(0.0, (sum, payment) => sum + payment.amount);

  double get activeDebtTotal =>
      _debts.fold(0.0, (sum, debt) => sum + max(0, debt.remainingAmount));

  double get totalOperationalCost =>
      _operationalCosts.fold(0.0, (sum, cost) => sum + cost.amount);

  List<OperationalCost> operationalCostsByMonth(DateTime monthYear) {
    final normalizedMonth = DateTime(monthYear.year, monthYear.month, 1);
    final result = _operationalCosts
        .where(
          (item) =>
              item.monthYear.year == normalizedMonth.year &&
              item.monthYear.month == normalizedMonth.month,
        )
        .toList();
    result.sort((a, b) => a.costName.compareTo(b.costName));
    return result;
  }

  double operationalCostTotalByMonth(DateTime monthYear) {
    return operationalCostsByMonth(monthYear)
        .fold(0.0, (sum, cost) => sum + cost.amount);
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
    final monthFormatter = DateFormat('MMM', 'id_ID');
    final productCostById = {
      for (final product in _products) product.id: product.costPrice,
    };

    return List.generate(6, (index) {
      final month = DateTime(now.year, now.month - 5 + index, 1);
      final nextMonth = DateTime(month.year, month.month + 1, 1);

      final transactions = _transactions
          .where(
            (transaction) =>
                !transaction.createdAt.isBefore(month) &&
                transaction.createdAt.isBefore(nextMonth),
          )
          .toList();
      final payments = _payments
          .where(
            (payment) =>
                !payment.paidAt.isBefore(month) &&
                payment.paidAt.isBefore(nextMonth),
          )
          .toList();
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
      final operationalCost = _operationalCosts
          .where(
            (item) =>
                item.monthYear.year == month.year &&
                item.monthYear.month == month.month,
          )
          .fold(0.0, (sum, item) => sum + item.amount);
      final activeDebtForMonth =
          month.year == now.year && month.month == now.month
              ? activeDebtTotal
              : 0.0;
      final rawLabel = monthFormatter.format(month);
      final label = rawLabel.isEmpty
          ? ''
          : '${rawLabel[0].toUpperCase()}${rawLabel.substring(1)}';

      return ReportSummary(
        label: label,
        revenue: revenue,
        cost: cost,
        operationalCost: operationalCost,
        activeDebtTotal: activeDebtForMonth,
      );
    });
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
    final nextQty = (_cart[product.id] ?? 0) + 1;
    _ensureCartQtyWithinStock(product.id, nextQty);
    _cart[product.id] = nextQty;
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
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
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
  }) async {
    await _repository.saveProduct(
      id: id,
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
    return _transactions.where((trx) => trx.customerId == customerId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  TransactionRecord? transactionById(String id) {
    for (final transaction in _transactions) {
      if (transaction.id == id) {
        return transaction;
      }
    }
    return null;
  }

  List<DebtRecord> debtsByCustomer(String customerId) {
    return _debts.where((debt) => debt.customerId == customerId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<DebtPayment> paymentsByCustomer(String customerId) {
    return _payments
        .where((payment) => payment.customerId == customerId)
        .toList()
      ..sort((a, b) => b.paidAt.compareTo(a.paidAt));
  }

  double totalPurchaseByCustomer(String customerId) {
    return transactionsByCustomer(
      customerId,
    ).fold(0.0, (sum, transaction) => sum + transaction.totalAmount);
  }

  double activeDebtByCustomer(String customerId) {
    return debtsByCustomer(
      customerId,
    ).fold(0.0, (sum, debt) => sum + max(0, debt.remainingAmount));
  }

  Future<void> _reloadPersistedData() async {
    final results = await Future.wait<dynamic>([
      _repository.fetchAppProfile(),
      _repository.fetchCategories(),
      _repository.fetchProducts(),
      _repository.fetchCustomers(),
      _repository.fetchTransactions(),
      _repository.fetchDebts(),
      _repository.fetchPayments(),
      _repository.fetchStockMovements(),
      _repository.fetchOperationalCosts(),
    ]);

    _appProfile = results[0] as AppProfile;
    _categories = results[1] as List<Category>;
    _products = results[2] as List<Product>;
    _customers = results[3] as List<Customer>;
    _transactions = results[4] as List<TransactionRecord>;
    _debts = results[5] as List<DebtRecord>;
    _payments = results[6] as List<DebtPayment>;
    _stockMovements = results[7] as List<StockMovement>;
    _operationalCosts = results[8] as List<OperationalCost>;
    _selectedCustomerId =
        _customers.any((item) => item.id == _selectedCustomerId)
            ? _selectedCustomerId
            : null;
  }

  void _ensureCartQtyWithinStock(String productId, int requestedQty) {
    final product = _products.cast<Product?>().firstWhere(
          (item) => item?.id == productId,
          orElse: () => null,
        );
    if (product == null) {
      throw Exception('Produk tidak ditemukan.');
    }
    if (requestedQty > product.stockQty) {
      throw Exception(
        'Stok ${product.name} tidak cukup. Sisa stok ${product.stockQty}.',
      );
    }
  }
}
