import '../models/app_models.dart';

abstract class PosRepository {
  Future<AppProfile?> fetchAppProfile();
  Future<List<Category>> fetchCategories();
  Future<List<Product>> fetchProducts();
  Future<List<Customer>> fetchCustomers();
  Future<List<TransactionRecord>> fetchTransactions();
  Future<List<DebtRecord>> fetchDebts();
  Future<List<DebtPayment>> fetchPayments();
  Future<List<StockMovement>> fetchStockMovements();
  Future<List<OperationalCost>> fetchOperationalCosts();

  Future<OperationalCost> saveOperationalCost({
    String? id,
    required DateTime monthYear,
    required String costName,
    required double amount,
  });

  Future<void> deleteOperationalCost(String id);

  Future<Customer> saveCustomer({
    String? id,
    required String name,
    required String phone,
    required String address,
    String? notes,
    required bool isActive,
  });

  Future<AppProfile> saveAppProfile({
    required String storeName,
    required String storeSubtitle,
    String? ownerName,
    String? photoPath,
  });

  Future<void> toggleCustomerActive(String customerId);

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
  });

  Future<void> deleteProduct(String productId);

  Future<TransactionRecord> checkout({
    required Map<String, int> cart,
    required String? customerId,
    required String customerName,
    required PaymentMethod paymentMethod,
    String? notes,
  });

  Future<void> recordDebtPayment({
    required String debtId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? notes,
  });
}
