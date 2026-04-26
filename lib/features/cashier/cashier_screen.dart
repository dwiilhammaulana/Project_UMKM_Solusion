import 'dart:math' as math;

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
  String _productQuery = '';
  String? _categoryId;
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
    final filteredProducts = state.products.where((product) {
      final matchesQuery = product.name.toLowerCase().contains(
            _productQuery.toLowerCase(),
          );
      final matchesCategory =
          _categoryId == null || product.categoryId == _categoryId;
      return matchesQuery && matchesCategory && product.isActive;
    }).toList();
    final filteredCustomers = state.customers.where((customer) {
      final input = _customerQuery.toLowerCase();
      return customer.isActive &&
          (customer.name.toLowerCase().contains(input) ||
              customer.phone.toLowerCase().contains(input));
    }).toList();
    final filteredTransactions = state.transactions.where((transaction) {
      final input = _historyQuery.toLowerCase();
      return input.isEmpty ||
          transaction.transactionCode.toLowerCase().contains(input) ||
          transaction.customerName.toLowerCase().contains(input);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.foam,
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
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildNewTransactionTab(
                  context,
                  state,
                  filteredProducts,
                  filteredCustomers,
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
  ) {
    final bottomOffset = math.max(
      shellBottomClearance(context),
      MediaQuery.viewInsetsOf(context).bottom + 20,
    );

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            shellBottomClearance(context, extraSpacing: 160),
          ),
          children: [
            HeroPanel(
              badge: const StatusChip(
                label: 'Kasir aktif',
                color: Colors.white,
                icon: Icons.flash_on_rounded,
              ),
              title: 'Flow kasir yang cepat dan tetap rapi.',
              subtitle:
                  'Pilih produk, tentukan pelanggan, lalu checkout tunai atau BON tanpa meninggalkan layar utama.',
              bottom: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  StatusChip(
                    label: '${state.cartCount} item di keranjang',
                    color: Colors.white,
                    icon: Icons.shopping_cart_rounded,
                  ),
                  StatusChip(
                    label: state.selectedPaymentMethod.label,
                    color: Colors.white,
                    icon: Icons.payments_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: '1. Pilih Produk',
                    subtitle: 'Cari menu dan tambahkan ke keranjang.',
                  ),
                  const SizedBox(height: 14),
                  AppSearchField(
                    fieldKey: const Key('cashier-product-search'),
                    hintText: 'Cari menu kopi atau makanan',
                    onChanged: (value) => setState(() => _productQuery = value),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        AppFilterChip(
                          label: 'Semua',
                          selected: _categoryId == null,
                          onSelected: (_) => setState(() => _categoryId = null),
                        ),
                        const SizedBox(width: 8),
                        ...state.categories.map(
                          (category) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: AppFilterChip(
                              label: category.name,
                              selected: _categoryId == category.id,
                              onSelected: (_) =>
                                  setState(() => _categoryId = category.id),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (filteredProducts.isEmpty)
                    const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Produk tidak ditemukan',
                      subtitle: 'Coba ubah kata kunci atau filter kategori.',
                    )
                  else
                    ...filteredProducts.map((product) {
                      final category = state.categories.firstWhere(
                        (item) => item.id == product.categoryId,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ProductCard(
                          product: product,
                          categoryName: category.name,
                          count: state.cart[product.id] ?? 0,
                          onEdit: null,
                          onAdd: () =>
                              ref.read(posStateProvider).addToCart(product),
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
                    const EmptyState(
                      icon: Icons.shopping_cart_outlined,
                      title: 'Keranjang kosong',
                      subtitle: 'Tambahkan produk dari daftar di atas.',
                    )
                  else ...[
                    ...state.cart.entries.map((entry) {
                      final product = state.products.firstWhere(
                        (item) => item.id == entry.key,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.54),
                            borderRadius: BorderRadius.circular(22),
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(AppFormatters.currency(
                                        product.sellPrice)),
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
                                      icon: const Icon(Icons.remove_rounded),
                                    ),
                                    Text(
                                      '${entry.value}',
                                      key: Key('cart-qty-${product.id}'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    IconButton(
                                      onPressed: () => ref
                                          .read(posStateProvider)
                                          .increaseCartQty(product.id),
                                      icon: const Icon(Icons.add_rounded),
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
                    SummaryRow(
                        label: 'Total item', value: '${state.cartCount}'),
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
                        child: ChoiceChip(
                          key: const Key('customer-general-chip'),
                          label: const Text('Umum / Tanpa Nama'),
                          selected: state.selectedCustomerId == null,
                          onSelected: (_) {
                            if (state.selectedPaymentMethod ==
                                PaymentMethod.bon) {
                              _showMessage(
                                context,
                                'Transaksi BON wajib memilih pelanggan terdaftar.',
                              );
                              return;
                            }
                            ref
                                .read(posStateProvider)
                                .setSelectedCustomer(null);
                          },
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
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text('Daftar Baru'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppSearchField(
                    fieldKey: const Key('cashier-customer-search'),
                    hintText: 'Cari pelanggan aktif',
                    onChanged: (value) =>
                        setState(() => _customerQuery = value),
                  ),
                  const SizedBox(height: 12),
                  if (filteredCustomers.isEmpty)
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
                              onTap: () => ref
                                  .read(posStateProvider)
                                  .setSelectedCustomer(customer.id),
                              child: Ink(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: state.selectedCustomerId == customer.id
                                      ? AppTheme.foam
                                      : Colors.white.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  children: [
                                    const AppMediaPreview(
                                      width: 54,
                                      height: 54,
                                      borderRadius: 27,
                                      placeholderIcon:
                                          Icons.person_outline_rounded,
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
                                      const Icon(
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: PaymentMethod.values.map((method) {
                      return ChoiceChip(
                        key: Key('payment-${method.name}'),
                        label: Text(method.label),
                        selected: state.selectedPaymentMethod == method,
                        onSelected: (_) =>
                            ref.read(posStateProvider).setPaymentMethod(method),
                      );
                    }).toList(),
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
                      prefixIcon: Icon(Icons.note_alt_outlined),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: bottomOffset,
          child: Container(
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
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: Text(
                    state.selectedPaymentMethod == PaymentMethod.bon
                        ? 'Simpan Transaksi BON'
                        : 'Selesaikan Transaksi',
                  ),
                ),
              ],
            ),
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      children: [
        HeroPanel(
          badge: const StatusChip(
            label: 'Riwayat transaksi',
            color: Colors.white,
            icon: Icons.history_rounded,
          ),
          title: 'Semua transaksi tetap rapi dan mudah ditelusuri.',
          subtitle:
              'Cari berdasarkan kode transaksi atau pelanggan, lalu buka detail lengkap kapan saja.',
          bottom: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              StatusChip(
                label: '${state.transactions.length} transaksi tersimpan',
                color: Colors.white,
                icon: Icons.receipt_long_rounded,
              ),
              StatusChip(
                label: AppFormatters.currency(state.totalRevenue),
                color: Colors.white,
                icon: Icons.payments_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.transactionCode,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${transaction.customerName} - ${AppFormatters.dateTime(transaction.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppFormatters.currency(transaction.totalAmount),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusChip(
                  label: transaction.paymentMethod.label,
                  color: AppTheme.deepTeal,
                  icon: Icons.payments_rounded,
                ),
                StatusChip(
                  label: '${transaction.totalQuantity} qty',
                  color: AppTheme.info,
                  icon: Icons.shopping_bag_rounded,
                ),
                StatusChip(
                  label: '${transaction.lineItemCount} jenis item',
                  color: AppTheme.success,
                  icon: Icons.list_alt_rounded,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SummaryRow(
              label: 'Nominal dibayar',
              value: AppFormatters.currency(transaction.amountPaid),
            ),
            SummaryRow(
              label: 'Kembalian',
              value: AppFormatters.currency(transaction.changeAmount),
            ),
          ],
        ),
      ),
    );
  }
}
