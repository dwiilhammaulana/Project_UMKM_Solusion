enum PaymentMethod { cash, qris, transfer, card, bon }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.cash => 'Tunai',
        PaymentMethod.qris => 'QRIS',
        PaymentMethod.transfer => 'Transfer',
        PaymentMethod.card => 'Kartu',
        PaymentMethod.bon => 'BON',
      };
}

enum DebtStatus { unpaid, partial, paid }

extension DebtStatusX on DebtStatus {
  String get label => switch (this) {
        DebtStatus.unpaid => 'UNPAID',
        DebtStatus.partial => 'PARTIAL',
        DebtStatus.paid => 'PAID',
      };
}

enum StockMovementType { stockIn, stockOut }

class Category {
  const Category({required this.id, required this.name, this.description});

  final String id;
  final String name;
  final String? description;
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.sellPrice,
    required this.costPrice,
    required this.stockQty,
    required this.minStock,
    required this.unit,
    this.rackLocation,
    this.imagePath,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String categoryId;
  final double sellPrice;
  final double costPrice;
  final int stockQty;
  final int minStock;
  final String unit;
  final String? rackLocation;
  final String? imagePath;
  final bool isActive;

  bool get isLowStock => stockQty <= minStock;

  Product copyWith({
    String? id,
    String? name,
    String? categoryId,
    double? sellPrice,
    double? costPrice,
    int? stockQty,
    int? minStock,
    String? unit,
    String? rackLocation,
    String? imagePath,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      sellPrice: sellPrice ?? this.sellPrice,
      costPrice: costPrice ?? this.costPrice,
      stockQty: stockQty ?? this.stockQty,
      minStock: minStock ?? this.minStock,
      unit: unit ?? this.unit,
      rackLocation: rackLocation ?? this.rackLocation,
      imagePath: imagePath ?? this.imagePath,
      isActive: isActive ?? this.isActive,
    );
  }
}

class AppProfile {
  const AppProfile({
    required this.id,
    required this.storeName,
    required this.storeSubtitle,
    this.ownerName,
    this.photoPath,
  });

  final String id;
  final String storeName;
  final String storeSubtitle;
  final String? ownerName;
  final String? photoPath;

  AppProfile copyWith({
    String? id,
    String? storeName,
    String? storeSubtitle,
    String? ownerName,
    String? photoPath,
  }) {
    return AppProfile(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      storeSubtitle: storeSubtitle ?? this.storeSubtitle,
      ownerName: ownerName ?? this.ownerName,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}

class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.notes,
    this.isActive = true,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final String address;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class TransactionItem {
  const TransactionItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.sellPrice,
  });

  final String productId;
  final String productName;
  final int quantity;
  final double sellPrice;

  double get subtotal => quantity * sellPrice;
}

class TransactionRecord {
  const TransactionRecord({
    required this.id,
    required this.transactionCode,
    required this.customerId,
    required this.customerName,
    required this.totalAmount,
    required this.paymentMethod,
    required this.amountPaid,
    required this.changeAmount,
    required this.createdAt,
    required this.items,
    this.notes,
  });

  final String id;
  final String transactionCode;
  final String? customerId;
  final String customerName;
  final double totalAmount;
  final PaymentMethod paymentMethod;
  final double amountPaid;
  final double changeAmount;
  final DateTime createdAt;
  final List<TransactionItem> items;
  final String? notes;

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  int get lineItemCount => items.length;
}

class DebtPayment {
  const DebtPayment({
    required this.id,
    required this.debtId,
    required this.customerId,
    required this.amount,
    required this.paymentMethod,
    required this.paidAt,
    this.notes,
  });

  final String id;
  final String debtId;
  final String customerId;
  final double amount;
  final PaymentMethod paymentMethod;
  final DateTime paidAt;
  final String? notes;
}

class DebtRecord {
  const DebtRecord({
    required this.id,
    required this.transactionId,
    required this.customerId,
    required this.customerName,
    required this.originalAmount,
    required this.paidAmount,
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    this.notes,
  });

  final String id;
  final String transactionId;
  final String customerId;
  final String customerName;
  final double originalAmount;
  final double paidAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? dueDate;
  final String? notes;

  double get remainingAmount => originalAmount - paidAmount;

  DebtStatus get status {
    if (remainingAmount <= 0) return DebtStatus.paid;
    if (paidAmount > 0) return DebtStatus.partial;
    return DebtStatus.unpaid;
  }

  int get ageInDays => DateTime.now().difference(createdAt).inDays;

  DebtRecord copyWith({
    String? id,
    String? transactionId,
    String? customerId,
    String? customerName,
    double? originalAmount,
    double? paidAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dueDate,
    String? notes,
  }) {
    return DebtRecord(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      originalAmount: originalAmount ?? this.originalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
    );
  }
}

class StockMovement {
  const StockMovement({
    required this.id,
    required this.referenceName,
    required this.quantity,
    required this.type,
    required this.createdAt,
    this.productId,
    this.notes,
  });

  final String id;
  final String? productId;
  final String referenceName;
  final double quantity;
  final StockMovementType type;
  final DateTime createdAt;
  final String? notes;
}

class OperationalCost {
  const OperationalCost({
    required this.id,
    required this.monthYear,
    required this.costName,
    required this.amount,
  });

  final String id;
  final DateTime monthYear;
  final String costName;
  final double amount;
}

class ReportSummary {
  const ReportSummary({
    required this.label,
    required this.revenue,
    required this.cost,
    required this.operationalCost,
    required this.activeDebtTotal,
  });

  final String label;
  final double revenue;
  final double cost;
  final double operationalCost;
  final double activeDebtTotal;

  double get netProfit => revenue - cost - operationalCost;
}
