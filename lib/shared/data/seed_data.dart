import '../models/app_models.dart';

class SeedData {
  const SeedData({
    required this.appProfile,
    required this.categories,
    required this.products,
    required this.customers,
    required this.transactions,
    required this.debts,
    required this.payments,
    required this.stockMovements,
    required this.operationalCosts,
    required this.reportSummaries,
  });

  final AppProfile appProfile;
  final List<Category> categories;
  final List<Product> products;
  final List<Customer> customers;
  final List<TransactionRecord> transactions;
  final List<DebtRecord> debts;
  final List<DebtPayment> payments;
  final List<StockMovement> stockMovements;
  final List<OperationalCost> operationalCosts;
  final List<ReportSummary> reportSummaries;
}

SeedData buildSeedData() {
  final now = DateTime.now();
  const appProfile = AppProfile(
    id: 'store-main',
    storeName: 'Warung Kopi Pertigaan Jati',
    storeSubtitle: 'Pantau penjualan, stok, dan bon dalam satu aplikasi.',
    ownerName: 'Pemilik Toko',
  );
  final categories = [
    const Category(id: 'cat-coffee', name: 'Kopi'),
    const Category(id: 'cat-food', name: 'Makanan'),
    const Category(id: 'cat-snack', name: 'Jajanan'),
    const Category(id: 'cat-raw', name: 'Bahan Baku'),
  ];

  final products = [
    const Product(
      id: 'prd-001',
      name: 'Kopi Hitam',
      categoryId: 'cat-coffee',
      sellPrice: 9000,
      costPrice: 4500,
      stockQty: 24,
      minStock: 8,
      unit: 'gelas',
      rackLocation: 'Bar A1',
      imagePath: null,
    ),
    const Product(
      id: 'prd-002',
      name: 'Kopi Susu Gula Aren',
      categoryId: 'cat-coffee',
      sellPrice: 16000,
      costPrice: 7600,
      stockQty: 11,
      minStock: 10,
      unit: 'gelas',
      rackLocation: 'Bar A2',
      imagePath: null,
    ),
    const Product(
      id: 'prd-003',
      name: 'Teh Tarik',
      categoryId: 'cat-coffee',
      sellPrice: 12000,
      costPrice: 5400,
      stockQty: 17,
      minStock: 7,
      unit: 'gelas',
      rackLocation: 'Bar A3',
      imagePath: null,
    ),
    const Product(
      id: 'prd-004',
      name: 'Indomie Telur',
      categoryId: 'cat-food',
      sellPrice: 18000,
      costPrice: 10000,
      stockQty: 8,
      minStock: 6,
      unit: 'porsi',
      rackLocation: 'Dapur B1',
      imagePath: null,
    ),
    const Product(
      id: 'prd-005',
      name: 'Roti Bakar Cokelat',
      categoryId: 'cat-food',
      sellPrice: 15000,
      costPrice: 6800,
      stockQty: 7,
      minStock: 6,
      unit: 'porsi',
      rackLocation: 'Dapur B2',
      imagePath: null,
    ),
    const Product(
      id: 'prd-006',
      name: 'Pisang Goreng',
      categoryId: 'cat-snack',
      sellPrice: 11000,
      costPrice: 5000,
      stockQty: 5,
      minStock: 5,
      unit: 'porsi',
      rackLocation: 'Snack C1',
      imagePath: null,
    ),
    const Product(
      id: 'prd-007',
      name: 'Keripik Singkong',
      categoryId: 'cat-snack',
      sellPrice: 8000,
      costPrice: 3500,
      stockQty: 13,
      minStock: 5,
      unit: 'bungkus',
      rackLocation: 'Snack C2',
      imagePath: null,
    ),
    const Product(
      id: 'prd-008',
      name: 'Air Mineral',
      categoryId: 'cat-snack',
      sellPrice: 6000,
      costPrice: 2500,
      stockQty: 9,
      minStock: 10,
      unit: 'botol',
      rackLocation: 'Rak Depan',
      imagePath: null,
    ),
  ];

  final customers = [
    Customer(
      id: 'cus-001',
      name: 'Pak Slamet',
      phone: '081234567890',
      address: 'RT 02 Pertigaan Jati',
      notes: 'Pelanggan tetap pagi hari',
      createdAt: now.subtract(const Duration(days: 120)),
    ),
    Customer(
      id: 'cus-002',
      name: 'Bu Rina',
      phone: '081298765432',
      address: 'Gang Mawar No. 3',
      notes: 'Sering pesan kopi susu dan roti bakar',
      createdAt: now.subtract(const Duration(days: 70)),
    ),
    Customer(
      id: 'cus-003',
      name: 'Mas Dimas',
      phone: '082112345678',
      address: 'Jl. Anggrek 8',
      notes: 'Biasa bayar transfer',
      createdAt: now.subtract(const Duration(days: 46)),
    ),
    Customer(
      id: 'cus-004',
      name: 'Mbak Sari',
      phone: '081377766655',
      address: 'Perum Griya Asri Blok C',
      createdAt: now.subtract(const Duration(days: 20)),
    ),
  ];

  const transactions = <TransactionRecord>[];

  const debts = <DebtRecord>[];

  const payments = <DebtPayment>[];

  const stockMovements = <StockMovement>[];

  final operationalCosts = [
    OperationalCost(
      id: 'opc-001',
      monthYear: DateTime(now.year, now.month, 1),
      costName: 'Listrik',
      amount: 420000,
    ),
    OperationalCost(
      id: 'opc-002',
      monthYear: DateTime(now.year, now.month, 1),
      costName: 'Gas',
      amount: 280000,
    ),
    OperationalCost(
      id: 'opc-003',
      monthYear: DateTime(now.year, now.month, 1),
      costName: 'Air',
      amount: 140000,
    ),
    OperationalCost(
      id: 'opc-004',
      monthYear: DateTime(now.year, now.month, 1),
      costName: 'Gaji Harian',
      amount: 850000,
    ),
  ];

  final reportSummaries = [
    const ReportSummary(
      label: 'Nov',
      revenue: 8900000,
      cost: 3600000,
      operationalCost: 1700000,
      activeDebtTotal: 540000,
    ),
    const ReportSummary(
      label: 'Des',
      revenue: 9400000,
      cost: 3920000,
      operationalCost: 1760000,
      activeDebtTotal: 610000,
    ),
    const ReportSummary(
      label: 'Jan',
      revenue: 9100000,
      cost: 3810000,
      operationalCost: 1800000,
      activeDebtTotal: 590000,
    ),
    const ReportSummary(
      label: 'Feb',
      revenue: 9800000,
      cost: 4100000,
      operationalCost: 1840000,
      activeDebtTotal: 670000,
    ),
    const ReportSummary(
      label: 'Mar',
      revenue: 10400000,
      cost: 4350000,
      operationalCost: 1920000,
      activeDebtTotal: 520000,
    ),
    const ReportSummary(
      label: 'Apr',
      revenue: 11200000,
      cost: 4480000,
      operationalCost: 1990000,
      activeDebtTotal: 400000,
    ),
  ];

  return SeedData(
    appProfile: appProfile,
    categories: categories,
    products: products,
    customers: customers,
    transactions: transactions,
    debts: debts,
    payments: payments,
    stockMovements: stockMovements,
    operationalCosts: operationalCosts,
    reportSummaries: reportSummaries,
  );
}
