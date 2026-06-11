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
    const Category(id: 'cat-nasi-paket', name: 'nasi paket'),
    const Category(id: 'cat-sembako', name: 'sembako'),
    const Category(id: 'cat-produk-kemasan', name: 'produk kemasan'),
  ];

  final products = [
    const Product(
      id: 'prd-001',
      name: 'Kopi Hitam',
      categoryId: 'cat-produk-kemasan',
      sellPrice: 9000,
      costPrice: 4500,
      stockQty: 24,
      minStock: 8,
      unit: 'Pcs',
      rackLocation: 'meja kasir',
      imagePath: null,
    ),
    const Product(
      id: 'prd-002',
      name: 'Kopi Susu Gula Aren',
      categoryId: 'cat-produk-kemasan',
      sellPrice: 16000,
      costPrice: 7600,
      stockQty: 11,
      minStock: 10,
      unit: 'Pack',
      rackLocation: 'etalase nasi',
      imagePath: null,
    ),
    const Product(
      id: 'prd-003',
      name: 'Teh Tarik',
      categoryId: 'cat-produk-kemasan',
      sellPrice: 12000,
      costPrice: 5400,
      stockQty: 17,
      minStock: 7,
      unit: 'Pcs',
      rackLocation: 'gantungan depan',
      imagePath: null,
    ),
    const Product(
      id: 'prd-004',
      name: 'Indomie Telur',
      categoryId: 'cat-nasi-paket',
      sellPrice: 18000,
      costPrice: 10000,
      stockQty: 8,
      minStock: 6,
      unit: 'Porsi',
      rackLocation: 'etalase nasi',
      imagePath: null,
    ),
    const Product(
      id: 'prd-005',
      name: 'Roti Bakar Cokelat',
      categoryId: 'cat-nasi-paket',
      sellPrice: 15000,
      costPrice: 6800,
      stockQty: 7,
      minStock: 6,
      unit: 'Porsi',
      rackLocation: 'etalase nasi',
      imagePath: null,
    ),
    const Product(
      id: 'prd-006',
      name: 'Pisang Goreng',
      categoryId: 'cat-nasi-paket',
      sellPrice: 11000,
      costPrice: 5000,
      stockQty: 5,
      minStock: 5,
      unit: 'Porsi',
      rackLocation: 'rak ambalan depan',
      imagePath: null,
    ),
    const Product(
      id: 'prd-007',
      name: 'Keripik Singkong',
      categoryId: 'cat-produk-kemasan',
      sellPrice: 8000,
      costPrice: 3500,
      stockQty: 13,
      minStock: 5,
      unit: 'Renceng',
      rackLocation: 'gantungan samping',
      imagePath: null,
    ),
    const Product(
      id: 'prd-008',
      name: 'Air Mineral',
      categoryId: 'cat-sembako',
      sellPrice: 6000,
      costPrice: 2500,
      stockQty: 9,
      minStock: 10,
      unit: 'Dus',
      rackLocation: 'rak ambalan depan',
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
  ReportSummary(
    label: 'Nov',
    period: DateTime(2025, 11, 1),
    revenue: 8900000,
    cost: 3600000,
    operationalCost: 1700000,
    activeDebtTotal: 540000,
  ),
  ReportSummary(
    label: 'Des',
    period: DateTime(2025, 12, 1),
    revenue: 9400000,
    cost: 3920000,
    operationalCost: 1760000,
    activeDebtTotal: 610000,
  ),
  ReportSummary(
    label: 'Jan',
    period: DateTime(2026, 1, 1),
    revenue: 9100000,
    cost: 3810000,
    operationalCost: 1800000,
    activeDebtTotal: 590000,
  ),
  ReportSummary(
    label: 'Feb',
    period: DateTime(2026, 2, 1),
    revenue: 9800000,
    cost: 4100000,
    operationalCost: 1840000,
    activeDebtTotal: 670000,
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
