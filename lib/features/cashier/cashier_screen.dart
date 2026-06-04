import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/models/app_models.dart';
import '../../shared/state/app_state.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/app_formatters.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/customer_form_sheet.dart';

class CashierScreen extends ConsumerStatefulWidget {
  const CashierScreen({super.key});

  @override
  ConsumerState<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends ConsumerState<CashierScreen> {
  static const _cashierPaymentMethods = [
    PaymentMethod.cash,
    PaymentMethod.qris,
    PaymentMethod.bon,
  ];

  String _productQuery = '';
  String? _categoryId;
  String? _rackLocation;
  String? _unit;
  String _customerQuery = '';
  String _historyQuery = '';
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(posStateProvider);
    final productQuery = _productQuery.trim().toLowerCase();
    final customerQuery = _customerQuery.trim().toLowerCase();
    final historyQuery = _historyQuery.trim().toLowerCase();
    final rackLocations = state.products
        .where((product) => product.isActive)
        .map((product) => product.rackLocation?.trim() ?? '')
        .where((rackLocation) => rackLocation.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final units = state.products
        .where((product) => product.isActive)
        .map((product) => product.unit.trim())
        .where((unit) => unit.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final filteredProducts = state.products.where((product) {
      final matchesQuery = productQuery.isEmpty ||
          product.name.toLowerCase().contains(productQuery);
      final matchesCategory =
          _categoryId == null || product.categoryId == _categoryId;
      final matchesRackLocation = _rackLocation == null ||
          (product.rackLocation?.trim() ?? '') == _rackLocation;
      final matchesUnit = _unit == null || product.unit.trim() == _unit;
      return matchesQuery &&
          matchesCategory &&
          matchesRackLocation &&
          matchesUnit &&
          product.isActive;
    }).toList();
    final filteredCustomers = state.customers.where((customer) {
      return customer.isActive &&
          (customerQuery.isEmpty ||
              customer.name.toLowerCase().contains(customerQuery) ||
              customer.phone.toLowerCase().contains(customerQuery));
    }).toList();
    final filteredTransactions = state.transactions.where((transaction) {
      return historyQuery.isEmpty ||
          transaction.transactionCode.toLowerCase().contains(historyQuery) ||
          transaction.customerName.toLowerCase().contains(historyQuery);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const _CashierTabHeader(),
          Expanded(
            child: TabBarView(
              children: [
                _buildNewTransactionTab(
                  context,
                  state,
                  filteredProducts,
                  filteredCustomers,
                  rackLocations,
                  units,
                ),
                _buildHistoryTab(context, state, filteredTransactions),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewTransactionTab(
    BuildContext context,
    PosAppState state,
    List<Product> filteredProducts,
    List<Customer> filteredCustomers,
    List<String> rackLocations,
    List<String> units,
  ) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        shellBottomClearance(context),
      ),
      children: [
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: '1. Pilih Produk',
                subtitle: 'Cari menu dan tambahkan ke keranjang.',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: AppSearchField(
                      fieldKey: const Key('cashier-product-search'),
                      hintText: 'Cari menu kopi atau makanan',
                      onChanged: (value) =>
                          setState(() => _productQuery = value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _ProductFilterButton(
                    categories: state.categories,
                    rackLocations: rackLocations,
                    units: units,
                    selectedCategoryId: _categoryId,
                    selectedRackLocation: _rackLocation,
                    selectedUnit: _unit,
                    onApply: (filters) {
                      setState(() {
                        _categoryId = filters.categoryId;
                        _rackLocation = filters.rackLocation;
                        _unit = filters.unit;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (filteredProducts.isEmpty)
                const Center(
                  child: EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Produk tidak ditemukan',
                    subtitle: 'Coba ubah kata kunci atau filter produk.',
                    maxWidth: 320,
                  ),
                )
              else
                ...filteredProducts.map((product) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ProductCard(
                      product: product,
                      categoryName: state.categoryNameById(
                        product.categoryId,
                      ),
                      count: state.cart[product.id] ?? 0,
                      mediaPlaceholderLabel: null,
                      onEdit: null,
                      onAdd: () {
                        try {
                          ref.read(posStateProvider).addToCart(product);
                        } catch (error) {
                          _showMessage(
                            context,
                            error.toString().replaceFirst('Exception: ', ''),
                          );
                        }
                      },
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: '2. Keranjang',
                subtitle: 'Atur jumlah item dan cek total belanja.',
              ),
              const SizedBox(height: 12),
              if (state.cart.isEmpty)
                const Center(
                  child: EmptyState(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Keranjang kosong',
                    subtitle: 'Tambahkan produk dari daftar di atas.',
                    maxWidth: 320,
                  ),
                )
              else ...[
                ...state.cart.entries.map((entry) {
                  final product = state.productById(entry.key);
                  if (product == null) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: AppTheme.deepTeal.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        children: [
                          AppMediaPreview(
                            imagePath: product.imagePath,
                            width: 62,
                            height: 62,
                            borderRadius: 18,
                            label: 'Foto',
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(AppFormatters.currency(product.sellPrice)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.foam,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => ref
                                      .read(posStateProvider)
                                      .decreaseCartQty(product.id),
                                  icon: const AppIcon(Icons.remove_rounded),
                                ),
                                Text(
                                  '${entry.value}',
                                  key: Key('cart-qty-${product.id}'),
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                IconButton(
                                  onPressed: () {
                                    try {
                                      ref
                                          .read(posStateProvider)
                                          .increaseCartQty(product.id);
                                    } catch (error) {
                                      _showMessage(
                                        context,
                                        error
                                            .toString()
                                            .replaceFirst('Exception: ', ''),
                                      );
                                    }
                                  },
                                  icon: const AppIcon(Icons.add_rounded),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const Divider(height: 24),
                SummaryRow(label: 'Total item', value: '${state.cartCount}'),
                SummaryRow(
                  label: 'Total belanja',
                  value: AppFormatters.currency(state.cartTotal),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: '3. Pelanggan & Pembayaran',
                subtitle:
                    'BON wajib memakai pelanggan aktif. Pilih metode dan simpan catatan bila perlu.',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      key: const Key('customer-general-chip'),
                      style: FilledButton.styleFrom(
                        backgroundColor: state.selectedCustomerId == null
                            ? AppTheme.deepTeal
                            : Colors.white,
                        foregroundColor: state.selectedCustomerId == null
                            ? Colors.white
                            : AppTheme.deepTeal,
                        side: BorderSide(
                          color: AppTheme.deepTeal.withValues(alpha: 0.18),
                        ),
                        minimumSize: const Size.fromHeight(56),
                      ),
                      onPressed: () {
                        if (state.selectedPaymentMethod == PaymentMethod.bon) {
                          _showMessage(
                            context,
                            'Transaksi BON wajib memilih pelanggan terdaftar.',
                          );
                          return;
                        }
                        ref.read(posStateProvider).setSelectedCustomer(null);
                      },
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Umum / Tanpa Nama'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        final customer =
                            await showCustomerFormSheet(context, ref);
                        if (!mounted) return;
                        if (customer != null) {
                          ref
                              .read(posStateProvider)
                              .setSelectedCustomer(customer.id);
                        }
                      },
                      icon: const AppIcon(Icons.person_add_alt_1_rounded),
                      label: const Text('Daftar Baru'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppSearchField(
                fieldKey: const Key('cashier-customer-search'),
                hintText: 'Cari pelanggan aktif',
                onChanged: (value) => setState(() => _customerQuery = value),
              ),
              const SizedBox(height: 12),
              if (state.selectedCustomer != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.foam,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      const AppMediaPreview(
                        width: 54,
                        height: 54,
                        borderRadius: 27,
                        placeholderIcon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.selectedCustomer!.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${state.selectedCustomer!.phone} - ${state.selectedCustomer!.address}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ref.read(posStateProvider).setSelectedCustomer(null);
                          setState(() => _customerQuery = '');
                        },
                        icon: const AppIcon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_customerQuery.trim().isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                        color: AppTheme.deepTeal.withValues(alpha: 0.08)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Ketik nama atau nomor pelanggan untuk mencari lalu pilih satu pelanggan.',
                  ),
                )
              else if (filteredCustomers.isEmpty)
                const EmptyState(
                  icon: Icons.people_outline_rounded,
                  title: 'Belum ada pelanggan cocok',
                  subtitle: 'Tambah pelanggan baru untuk transaksi BON.',
                )
              else
                ...filteredCustomers.take(5).map(
                      (customer) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            ref
                                .read(posStateProvider)
                                .setSelectedCustomer(customer.id);
                            setState(() => _customerQuery = '');
                          },
                          child: Ink(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: state.selectedCustomerId == customer.id
                                  ? AppTheme.foam
                                  : Colors.white,
                              border: state.selectedCustomerId == customer.id
                                  ? null
                                  : Border.all(
                                      color: AppTheme.deepTeal
                                          .withValues(alpha: 0.08)),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                const AppMediaPreview(
                                  width: 54,
                                  height: 54,
                                  borderRadius: 27,
                                  placeholderIcon: Icons.person_outline_rounded,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customer.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${customer.phone} - ${customer.address}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                if (state.selectedCustomerId == customer.id)
                                  const AppIcon(
                                    Icons.check_circle_rounded,
                                    color: AppTheme.success,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final method in _cashierPaymentMethods) ...[
                    Expanded(
                      child: _PaymentMethodButton(
                        key: Key('payment-${method.name}'),
                        label: _cashierPaymentLabel(method),
                        selected: _isCashierPaymentSelected(
                          method,
                          state.selectedPaymentMethod,
                        ),
                        onTap: () =>
                            ref.read(posStateProvider).setPaymentMethod(method),
                      ),
                    ),
                    if (method != _cashierPaymentMethods.last)
                      const SizedBox(width: 6),
                  ],
                ],
              ),
              if (state.selectedPaymentMethod == PaymentMethod.bon &&
                  state.selectedCustomerId == null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Mode BON aktif. Pilih pelanggan terdaftar terlebih dulu sebelum checkout.',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: 'Catatan transaksi (opsional)',
                  prefixIcon: AppIcon(Icons.note_alt_outlined),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: AppTheme.frostedDecoration(radius: 30),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SummaryRow(
                label: 'Total checkout',
                value: AppFormatters.currency(state.cartTotal),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                key: const Key('cashier-checkout-button'),
                onPressed: () async {
                  try {
                    final transaction =
                        await ref.read(posStateProvider).checkout(
                              notes: _notesController.text.trim().isEmpty
                                  ? null
                                  : _notesController.text.trim(),
                            );
                    _notesController.clear();
                    if (!context.mounted) return;
                    await _showReceiptSheet(context, transaction);
                  } catch (error) {
                    if (!context.mounted) return;
                    _showMessage(
                      context,
                      error.toString().replaceFirst('Exception: ', ''),
                    );
                  }
                },
                icon: const AppIcon(Icons.receipt_long_rounded),
                label: Text(
                  state.selectedPaymentMethod == PaymentMethod.bon
                      ? 'Simpan Transaksi BON'
                      : 'Selesaikan Transaksi',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab(
    BuildContext context,
    PosAppState state,
    List<TransactionRecord> filteredTransactions,
  ) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        shellBottomClearance(context),
      ),
      children: [
        AppSectionCard(
          child: AppSearchField(
            fieldKey: const Key('cashier-history-search'),
            hintText: 'Cari kode transaksi atau nama pelanggan',
            onChanged: (value) => setState(() => _historyQuery = value),
          ),
        ),
        const SizedBox(height: 20),
        if (filteredTransactions.isEmpty)
          const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Belum ada transaksi cocok',
            subtitle: 'Ubah kata kunci pencarian atau buat transaksi baru.',
          )
        else
          ...filteredTransactions.map(
            (transaction) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TransactionHistoryCard(transaction: transaction),
            ),
          ),
      ],
    );
  }

  Future<void> _showReceiptSheet(
    BuildContext context,
    TransactionRecord transaction,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BottomSheetContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaction.paymentMethod == PaymentMethod.bon
                    ? 'Transaksi BON Tersimpan'
                    : 'Transaksi Berhasil',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${transaction.transactionCode} - ${AppFormatters.dateTime(transaction.createdAt)}',
              ),
              const SizedBox(height: 16),
              AppSectionCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SummaryRow(
                        label: 'Pelanggan', value: transaction.customerName),
                    SummaryRow(
                      label: 'Metode bayar',
                      value: transaction.paymentMethod.label,
                    ),
                    SummaryRow(
                      label: 'Qty total produk',
                      value: '${transaction.totalQuantity}',
                    ),
                    SummaryRow(
                      label: 'Jumlah jenis item',
                      value: '${transaction.lineItemCount}',
                    ),
                    SummaryRow(
                      label: 'Total',
                      value: AppFormatters.currency(transaction.totalAmount),
                    ),
                    if (transaction.paymentMethod == PaymentMethod.bon)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('Struk dummy: BON - Belum Lunas'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Tutup'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      key: const Key('receipt-view-detail-button'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        this
                            .context
                            .go('/cashier/transactions/${transaction.id}');
                      },
                      child: const Text('Lihat Detail Transaksi'),
                    ),
                  ),
                ],
              ),
              if (transaction.paymentMethod == PaymentMethod.bon) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      this.context.go('/debts');
                    },
                    child: const Text('Buka daftar BON'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _cashierPaymentLabel(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.cash => 'Tunai',
      PaymentMethod.bon => 'BON',
      _ => 'Non Tunai',
    };
  }

  bool _isCashierPaymentSelected(
    PaymentMethod option,
    PaymentMethod selected,
  ) {
    if (option == PaymentMethod.qris) {
      return selected == PaymentMethod.qris ||
          selected == PaymentMethod.transfer ||
          selected == PaymentMethod.card;
    }
    return selected == option;
  }
}

class _TransactionHistoryCard extends StatelessWidget {
  const _TransactionHistoryCard({required this.transaction});

  final TransactionRecord transaction;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('transaction-history-tile-${transaction.id}'),
      borderRadius: BorderRadius.circular(28),
      onTap: () => context.go('/cashier/transactions/${transaction.id}'),
      child: Ink(
        decoration: AppTheme.frostedDecoration(radius: 28),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                transaction.transactionCode,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppFormatters.currency(transaction.totalAmount),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _CashierTabHeader extends StatelessWidget {
  const _CashierTabHeader();

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topInset + 12, 20, 14),
      decoration: BoxDecoration(
        color: AppTheme.deepTeal,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.midnight.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const TabBar(
          tabs: [
            Tab(
              key: Key('cashier-tab-new'),
              text: 'Transaksi Baru',
            ),
            Tab(
              key: Key('cashier-tab-history'),
              text: 'Riwayat Transaksi',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductFilters {
  const _ProductFilters({
    this.categoryId,
    this.rackLocation,
    this.unit,
  });

  final String? categoryId;
  final String? rackLocation;
  final String? unit;
}

enum _ProductFilterField { category, rackLocation, unit }

class _ProductFilterButton extends StatefulWidget {
  const _ProductFilterButton({
    required this.categories,
    required this.rackLocations,
    required this.units,
    required this.selectedCategoryId,
    required this.selectedRackLocation,
    required this.selectedUnit,
    required this.onApply,
  });

  final List<Category> categories;
  final List<String> rackLocations;
  final List<String> units;
  final String? selectedCategoryId;
  final String? selectedRackLocation;
  final String? selectedUnit;
  final ValueChanged<_ProductFilters> onApply;

  @override
  State<_ProductFilterButton> createState() => _ProductFilterButtonState();
}

class _ProductFilterButtonState extends State<_ProductFilterButton> {
  final MenuController _menuController = MenuController();
  String? _draftCategoryId;
  String? _draftRackLocation;
  String? _draftUnit;
  _ProductFilterField? _expandedField;

  @override
  void initState() {
    super.initState();
    _draftCategoryId = widget.selectedCategoryId;
    _draftRackLocation = widget.selectedRackLocation;
    _draftUnit = widget.selectedUnit;
  }

  @override
  void didUpdateWidget(covariant _ProductFilterButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed = oldWidget.selectedCategoryId != widget.selectedCategoryId ||
        oldWidget.selectedRackLocation != widget.selectedRackLocation ||
        oldWidget.selectedUnit != widget.selectedUnit;
    if (changed) {
      _syncDraftsFromAppliedFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.selectedCategoryId != null ||
        widget.selectedRackLocation != null ||
        widget.selectedUnit != null;

    return MenuAnchor(
      controller: _menuController,
      alignmentOffset: const Offset(-252, 8),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(8),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
      menuChildren: [
        SizedBox(
          width: 310,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_expandedField == null)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ProductFilterSummaryTile(
                        title: 'Kategori',
                        value: _categoryLabel(),
                        onTap: () => setState(
                          () => _expandedField = _ProductFilterField.category,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ProductFilterSummaryTile(
                        title: 'Lokasi rak',
                        value: _draftRackLocation ?? 'Semua lokasi',
                        onTap: () => setState(
                          () =>
                              _expandedField = _ProductFilterField.rackLocation,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ProductFilterSummaryTile(
                        title: 'Satuan',
                        value: _draftUnit ?? 'Semua satuan',
                        onTap: () => setState(
                          () => _expandedField = _ProductFilterField.unit,
                        ),
                      ),
                    ],
                  )
                else
                  _buildExpandedChoices(context),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        key: const Key('cashier-category-filter-reset'),
                        onPressed: () {
                          setState(_clearDrafts);
                          widget.onApply(const _ProductFilters());
                          _menuController.close();
                        },
                        child: const Text('Atur ulang'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        key: const Key('cashier-category-filter-apply'),
                        onPressed: () {
                          widget.onApply(
                            _ProductFilters(
                              categoryId: _draftCategoryId,
                              rackLocation: _draftRackLocation,
                              unit: _draftUnit,
                            ),
                          );
                          _menuController.close();
                        },
                        child: const Text('Terapkan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
      builder: (context, controller, child) {
        return IconButton(
          key: const Key('cashier-category-filter-button'),
          tooltip: 'Filter produk',
          style: IconButton.styleFrom(
            backgroundColor: isActive ? AppTheme.deepTeal : AppTheme.foam,
            foregroundColor: isActive ? Colors.white : AppTheme.deepTeal,
            fixedSize: const Size(52, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          onPressed: () {
            setState(() {
              _syncDraftsFromAppliedFilters();
              _expandedField = null;
            });
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const AppIcon(Icons.tune_rounded),
        );
      },
    );
  }

  void _syncDraftsFromAppliedFilters() {
    _draftCategoryId = widget.selectedCategoryId;
    _draftRackLocation = widget.selectedRackLocation;
    _draftUnit = widget.selectedUnit;
  }

  void _clearDrafts() {
    _draftCategoryId = null;
    _draftRackLocation = null;
    _draftUnit = null;
    _expandedField = null;
  }

  Widget _buildExpandedChoices(BuildContext context) {
    final field = _expandedField!;
    final title = switch (field) {
      _ProductFilterField.category => 'Kategori',
      _ProductFilterField.rackLocation => 'Lokasi rak',
      _ProductFilterField.unit => 'Satuan',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Kembali',
              onPressed: () => setState(() => _expandedField = null),
              icon: const AppIcon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 230),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: switch (field) {
                _ProductFilterField.category => [
                    _ProductFilterOption(
                      label: 'Semua kategori',
                      selected: _draftCategoryId == null,
                      onTap: () {
                        setState(() {
                          _draftCategoryId = null;
                          _expandedField = null;
                        });
                      },
                    ),
                    const SizedBox(height: 6),
                    for (final category in widget.categories)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _ProductFilterOption(
                          label: category.name,
                          selected: _draftCategoryId == category.id,
                          onTap: () {
                            setState(() {
                              _draftCategoryId = category.id;
                              _expandedField = null;
                            });
                          },
                        ),
                      ),
                  ],
                _ProductFilterField.rackLocation => [
                    _ProductFilterOption(
                      label: 'Semua lokasi',
                      selected: _draftRackLocation == null,
                      onTap: () {
                        setState(() {
                          _draftRackLocation = null;
                          _expandedField = null;
                        });
                      },
                    ),
                    const SizedBox(height: 6),
                    if (widget.rackLocations.isEmpty)
                      const _ProductFilterEmptyOption(
                        label: 'Belum ada lokasi rak',
                      )
                    else
                      for (final rackLocation in widget.rackLocations)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _ProductFilterOption(
                            label: rackLocation,
                            selected: _draftRackLocation == rackLocation,
                            onTap: () {
                              setState(() {
                                _draftRackLocation = rackLocation;
                                _expandedField = null;
                              });
                            },
                          ),
                        ),
                  ],
                _ProductFilterField.unit => [
                    _ProductFilterOption(
                      label: 'Semua satuan',
                      selected: _draftUnit == null,
                      onTap: () {
                        setState(() {
                          _draftUnit = null;
                          _expandedField = null;
                        });
                      },
                    ),
                    const SizedBox(height: 6),
                    if (widget.units.isEmpty)
                      const _ProductFilterEmptyOption(
                        label: 'Belum ada satuan',
                      )
                    else
                      for (final unit in widget.units)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _ProductFilterOption(
                            label: unit,
                            selected: _draftUnit == unit,
                            onTap: () {
                              setState(() {
                                _draftUnit = unit;
                                _expandedField = null;
                              });
                            },
                          ),
                        ),
                  ],
              },
            ),
          ),
        ),
      ],
    );
  }

  String _categoryLabel() {
    if (_draftCategoryId == null) {
      return 'Semua kategori';
    }
    for (final category in widget.categories) {
      if (category.id == _draftCategoryId) {
        return category.name;
      }
    }
    return 'Kategori dipilih';
  }
}

class _ProductFilterSummaryTile extends StatelessWidget {
  const _ProductFilterSummaryTile({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.foam.withValues(alpha: 0.50),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.deepTeal.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.subtext,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.ink,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const AppIcon(
                Icons.keyboard_arrow_down_rounded,
                color: AppTheme.deepTeal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductFilterEmptyOption extends StatelessWidget {
  const _ProductFilterEmptyOption({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppTheme.foam.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _ProductFilterOption extends StatelessWidget {
  const _ProductFilterOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.deepTeal.withValues(alpha: 0.10)
                : AppTheme.foam.withValues(alpha: 0.50),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppTheme.deepTeal.withValues(alpha: 0.20)
                  : AppTheme.deepTeal.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: selected ? AppTheme.deepTeal : AppTheme.ink,
                        fontWeight:
                            selected ? FontWeight.w900 : FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: 10),
              AppIcon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppTheme.deepTeal : AppTheme.subtext,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodButton extends StatelessWidget {
  const _PaymentMethodButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = selected ? Colors.white : AppTheme.deepTeal;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppTheme.deepTeal : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppTheme.deepTeal
                  : AppTheme.deepTeal.withValues(alpha: 0.28),
              width: 1.2,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
