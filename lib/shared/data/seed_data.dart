import '../models/app_models.dart';

class SeedData {
  const SeedData({
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

  final transactions = [
    TransactionRecord(
      id: 'trx-001',
      transactionCode: 'TRX-20260421-001',
      customerId: 'cus-001',
      customerName: 'Pak Slamet',
      totalAmount: 31000,
      paymentMethod: PaymentMethod.cash,
      amountPaid: 31000,
      changeAmount: 0,
      createdAt: now.subtract(const Duration(hours: 2)),
      items: const [
        TransactionItem(
          productId: 'prd-001',
          productName: 'Kopi Hitam',
          quantity: 1,
          sellPrice: 9000,
        ),
        TransactionItem(
          productId: 'prd-004',
          productName: 'Indomie Telur',
          quantity: 1,
          sellPrice: 18000,
        ),
        TransactionItem(
          productId: 'prd-008',
          productName: 'Air Mineral',
          quantity: 1,
          sellPrice: 6000,
        ),
      ],
    ),
    TransactionRecord(
      id: 'trx-002',
      transactionCode: 'TRX-20260421-002',
      customerId: null,
      customerName: 'Umum / Tanpa Nama',
      totalAmount: 27000,
      paymentMethod: PaymentMethod.qris,
      amountPaid: 27000,
      changeAmount: 0,
      createdAt: now.subtract(const Duration(hours: 5)),
      items: const [
        TransactionItem(
          productId: 'prd-002',
          productName: 'Kopi Susu Gula Aren',
          quantity: 1,
          sellPrice: 16000,
        ),
        TransactionItem(
          productId: 'prd-006',
          productName: 'Pisang Goreng',
          quantity: 1,
          sellPrice: 11000,
        ),
      ],
    ),
    TransactionRecord(
      id: 'trx-003',
      transactionCode: 'TRX-20260417-001',
      customerId: 'cus-002',
      customerName: 'Bu Rina',
      totalAmount: 47000,
      paymentMethod: PaymentMethod.bon,
      amountPaid: 0,
      changeAmount: 0,
      createdAt: now.subtract(const Duration(days: 4)),
      items: const [
        TransactionItem(
          productId: 'prd-002',
          productName: 'Kopi Susu Gula Aren',
          quantity: 2,
          sellPrice: 16000,
        ),
        TransactionItem(
          productId: 'prd-005',
          productName: 'Roti Bakar Cokelat',
          quantity: 1,
          sellPrice: 15000,
        ),
      ],
      notes: 'BON - Belum Lunas',
    ),
    TransactionRecord(
      id: 'trx-004',
      transactionCode: 'TRX-20260406-003',
      customerId: 'cus-001',
      customerName: 'Pak Slamet',
      totalAmount: 36000,
      paymentMethod: PaymentMethod.bon,
      amountPaid: 0,
      changeAmount: 0,
      createdAt: now.subtract(const Duration(days: 15)),
      items: const [
        TransactionItem(
          productId: 'prd-001',
          productName: 'Kopi Hitam',
          quantity: 2,
          sellPrice: 9000,
        ),
        TransactionItem(
          productId: 'prd-006',
          productName: 'Pisang Goreng',
          quantity: 1,
          sellPrice: 11000,
        ),
        TransactionItem(
          productId: 'prd-007',
          productName: 'Keripik Singkong',
          quantity: 1,
          sellPrice: 8000,
        ),
      ],
      notes: 'BON - Belum Lunas',
    ),
    TransactionRecord(
      id: 'trx-005',
      transactionCode: 'TRX-20260412-002',
      customerId: 'cus-003',
      customerName: 'Mas Dimas',
      totalAmount: 42000,
      paymentMethod: PaymentMethod.transfer,
      amountPaid: 42000,
      changeAmount: 0,
      createdAt: now.subtract(const Duration(days: 9)),
      items: const [
        TransactionItem(
          productId: 'prd-003',
          productName: 'Teh Tarik',
          quantity: 2,
          sellPrice: 12000,
        ),
        TransactionItem(
          productId: 'prd-004',
          productName: 'Indomie Telur',
          quantity: 1,
          sellPrice: 18000,
        ),
      ],
    ),
    TransactionRecord(
      id: 'trx-006',
      transactionCode: 'TRX-20260414-001',
      customerId: 'cus-004',
      customerName: 'Mbak Sari',
      totalAmount: 52000,
      paymentMethod: PaymentMethod.bon,
      amountPaid: 0,
      changeAmount: 0,
      createdAt: now.subtract(const Duration(days: 10)),
      items: const [
        TransactionItem(
          productId: 'prd-002',
          productName: 'Kopi Susu Gula Aren',
          quantity: 1,
          sellPrice: 16000,
        ),
        TransactionItem(
          productId: 'prd-004',
          productName: 'Indomie Telur',
          quantity: 2,
          sellPrice: 18000,
        ),
      ],
      notes: 'BON - Cicilan berjalan',
    ),
  ];

  final debts = [
    DebtRecord(
      id: 'debt-001',
      transactionId: 'trx-003',
      customerId: 'cus-002',
      customerName: 'Bu Rina',
      originalAmount: 47000,
      paidAmount: 15000,
      dueDate: now.add(const Duration(days: 3)),
      createdAt: now.subtract(const Duration(days: 4)),
      updatedAt: now.subtract(const Duration(days: 1)),
      notes: 'Cicilan pertama sudah masuk',
    ),
    DebtRecord(
      id: 'debt-002',
      transactionId: 'trx-004',
      customerId: 'cus-001',
      customerName: 'Pak Slamet',
      originalAmount: 36000,
      paidAmount: 0,
      dueDate: now.subtract(const Duration(days: 1)),
      createdAt: now.subtract(const Duration(days: 15)),
      updatedAt: now.subtract(const Duration(days: 15)),
      notes: 'Belum ada pembayaran',
    ),
    DebtRecord(
      id: 'debt-003',
      transactionId: 'trx-006',
      customerId: 'cus-004',
      customerName: 'Mbak Sari',
      originalAmount: 52000,
      paidAmount: 32000,
      dueDate: now.add(const Duration(days: 5)),
      createdAt: now.subtract(const Duration(days: 10)),
      updatedAt: now.subtract(const Duration(days: 2)),
      notes: 'Sisa tinggal sedikit',
    ),
  ];

  final payments = [
    DebtPayment(
      id: 'pay-001',
      debtId: 'debt-001',
      customerId: 'cus-002',
      amount: 15000,
      paymentMethod: PaymentMethod.transfer,
      paidAt: now.subtract(const Duration(days: 1)),
      notes: 'Transfer malam',
    ),
    DebtPayment(
      id: 'pay-002',
      debtId: 'debt-003',
      customerId: 'cus-004',
      amount: 32000,
      paymentMethod: PaymentMethod.cash,
      paidAt: now.subtract(const Duration(days: 2)),
      notes: 'Bayar setelah kerja',
    ),
  ];

  final stockMovements = [
    StockMovement(
      id: 'stm-001',
      productId: 'prd-002',
      referenceName: 'Kopi Susu Gula Aren',
      quantity: 3,
      type: StockMovementType.stockOut,
      createdAt: now.subtract(const Duration(hours: 5)),
      notes: 'Penjualan pagi',
    ),
    StockMovement(
      id: 'stm-002',
      productId: 'prd-004',
      referenceName: 'Indomie Telur',
      quantity: 2,
      type: StockMovementType.stockOut,
      createdAt: now.subtract(const Duration(hours: 2)),
      notes: 'Transaksi meja 2',
    ),
    StockMovement(
      id: 'stm-003',
      productId: 'prd-006',
      referenceName: 'Pisang Goreng',
      quantity: 1,
      type: StockMovementType.stockOut,
      createdAt: now.subtract(const Duration(days: 1)),
    ),
    StockMovement(
      id: 'stm-004',
      productId: 'prd-008',
      referenceName: 'Air Mineral',
      quantity: 12,
      type: StockMovementType.stockIn,
      createdAt: now.subtract(const Duration(days: 3)),
      notes: 'Restock distributor',
    ),
  ];

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
