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

class _CashierScreenState extends ConsumerState<CashierScreen>
    with TickerProviderStateMixin {
  static const _cashierPaymentMethods = [
    PaymentMethod.cash,
    PaymentMethod.qris,
    PaymentMethod.bon,
  ];

  String _customerQuery = '';
  String _historyQuery = '';
  String _pendingCustomerQuery = '';
  String _pendingProductQuery = '';
  bool _showPendingProductSuggestions = false;
  String? _selectedPendingTransactionId;
  PaymentMethod _pendingPaymentMethod = PaymentMethod.cash;
  late final TabController _tabController;
  final TextEditingController _notesController = TextEditingController();
  AnimationController? _bonCustomerPulseController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _ensureBonCustomerPulseController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bonCustomerPulseController?.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(posStateProvider);
    final customerQuery = _customerQuery.trim().toLowerCase();
    final historyQuery = _historyQuery.trim().toLowerCase();
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

    return Column(
      children: [
        _CashierTabHeader(controller: _tabController),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildNewTransactionTab(
                context,
                state,
                filteredCustomers,
              ),
              _buildOngoingTab(context, state),
              _buildHistoryTab(context, state, filteredTransactions),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNewTransactionTab(
    BuildContext context,
    PosAppState state,
    List<Customer> filteredCustomers,
  ) {
    final needsBonCustomer = state.selectedPaymentMethod == PaymentMethod.bon &&
        state.selectedCustomerId == null;
    _syncBonCustomerPulse(needsBonCustomer);
    final bonCustomerPulseController = _ensureBonCustomerPulseController();

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
              const _CashierSectionHeader(
                title: '1. Konfirmasi Produk',
                infoMessage:
                    'Produk yang dipilih dari halaman Produk akan masuk ke daftar ini.',
              ),
              const SizedBox(height: 12),
              if (state.cart.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const EmptyState(
                        icon: Icons.shopping_cart_outlined,
                        title: 'Belum ada produk dipilih',
                        subtitle:
                            'Pilih produk dari halaman Produk terlebih dahulu.',
                        maxWidth: 320,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: const Key('cashier-open-products-button'),
                        onPressed: () => context.go('/products'),
                        icon: const AppIcon(Icons.inventory_2_rounded),
                        label: const Text('Buka Halaman Produk'),
                      ),
                    ],
                  ),
                )
              else ...[
                ...state.cart.entries.map((entry) {
                  final product = state.productById(entry.key);
                  if (product == null) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: AppTheme.deepTeal.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        children: [
                          AppMediaPreview(
                            imagePath: product.imagePath,
                            width: 44,
                            height: 44,
                            borderRadius: 14,
                            label: null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppFormatters.currency(product.sellPrice),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppTheme.foam,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 30,
                                      height: 34,
                                      child: IconButton(
                                        tooltip: 'Kurangi qty',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: entry.value <= 1
                                            ? null
                                            : () => ref
                                                .read(posStateProvider)
                                                .decreaseCartQty(product.id),
                                        icon: const AppIcon(
                                          Icons.remove_rounded,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 24,
                                      child: Text(
                                        '${entry.value}',
                                        key: Key('cart-qty-${product.id}'),
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 30,
                                      height: 34,
                                      child: IconButton(
                                        tooltip: 'Tambah qty',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          try {
                                            ref
                                                .read(posStateProvider)
                                                .increaseCartQty(product.id);
                                          } catch (error) {
                                            _showMessage(
                                              context,
                                              error.toString().replaceFirst(
                                                  'Exception: ', ''),
                                            );
                                          }
                                        },
                                        icon: const AppIcon(
                                          Icons.add_rounded,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                key: Key('cart-remove-${product.id}'),
                                tooltip: 'Hapus produk',
                                style: IconButton.styleFrom(
                                  fixedSize: const Size(34, 34),
                                  minimumSize: const Size(34, 34),
                                  padding: EdgeInsets.zero,
                                  foregroundColor: AppTheme.danger,
                                  backgroundColor:
                                      AppTheme.danger.withValues(alpha: 0.08),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: AppTheme.danger.withValues(
                                        alpha: 0.24,
                                      ),
                                    ),
                                  ),
                                ),
                                onPressed: () =>
                                    _confirmRemoveCartItem(context, product),
                                icon: const AppIcon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                ),
                              ),
                            ],
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
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.go('/products'),
                  icon: const AppIcon(Icons.add_shopping_cart_rounded),
                  label: const Text('Tambah Produk Lain'),
                ),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: AppTheme.deepTeal.withValues(alpha: 0.10),
                ),
              ),
              const _CashierSectionHeader(
                title: '2. Pelanggan & Pembayaran',
                infoMessage:
                    'Ketik nama atau nomor pelanggan untuk mencari lalu pilih satu pelanggan. BON wajib memakai pelanggan aktif.',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _BonCustomerSearchPulse(
                      active: needsBonCustomer,
                      animation: bonCustomerPulseController,
                      child: AppSearchField(
                        fieldKey: const Key('cashier-customer-search'),
                        hintText: 'Cari pelanggan aktif',
                        showPrefixIcon: false,
                        onChanged: (value) =>
                            setState(() => _customerQuery = value),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    key: const Key('customer-add-icon-button'),
                    tooltip: 'Daftar pelanggan baru',
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.deepTeal,
                      foregroundColor: Colors.white,
                      fixedSize: const Size(44, 44),
                      minimumSize: const Size(44, 44),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      final customer = await showCustomerFormSheet(
                        context,
                        ref,
                      );
                      if (!mounted) return;
                      if (customer != null) {
                        ref
                            .read(posStateProvider)
                            .setSelectedCustomer(customer.id);
                      }
                    },
                    icon: const AppIcon(Icons.person_add_alt_1_rounded),
                  ),
                ],
              ),
              if (needsBonCustomer) ...[
                const SizedBox(height: 8),
                const _BonCustomerNote(),
              ],
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
              if (_customerQuery.trim().isNotEmpty && filteredCustomers.isEmpty)
                const EmptyState(
                  icon: Icons.people_outline_rounded,
                  title: 'Belum ada pelanggan cocok',
                  subtitle: 'Tambah pelanggan baru untuk transaksi BON.',
                )
              else if (_customerQuery.trim().isNotEmpty)
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
                            ref.read(posStateProvider).setPaymentMethod(
                                  method == PaymentMethod.qris
                                      ? PaymentMethod.qris
                                      : method,
                                ),
                      ),
                    ),
                    if (method != _cashierPaymentMethods.last)
                      const SizedBox(width: 6),
                  ],
                ],
              ),
              if (_isCashierPaymentSelected(
                PaymentMethod.qris,
                state.selectedPaymentMethod,
              )) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _PaymentMethodButton(
                        key: const Key('payment-noncash-dana'),
                        label: 'E-Wallet',
                        selected:
                            state.selectedPaymentMethod == PaymentMethod.qris,
                        onTap: () => ref
                            .read(posStateProvider)
                            .setPaymentMethod(PaymentMethod.qris),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _PaymentMethodButton(
                        key: const Key('payment-noncash-bank'),
                        label: 'Bank',
                        selected: state.selectedPaymentMethod ==
                            PaymentMethod.transfer,
                        onTap: () => ref
                            .read(posStateProvider)
                            .setPaymentMethod(PaymentMethod.transfer),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: 'Catatan transaksi (opsional)',
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
                  if (state.cartContainsNasiPaket) {
                    try {
                      final notes = _notesController.text.trim();
                      await ref
                          .read(posStateProvider)
                          .moveCartToPendingTransaction(
                            notes: notes.isEmpty ? null : notes,
                          );
                      _notesController.clear();
                      if (!context.mounted) return;
                      setState(() {
                        _selectedPendingTransactionId = null;
                        _pendingPaymentMethod = PaymentMethod.cash;
                      });
                      _tabController.animateTo(1);
                      _showMessage(
                        context,
                        'Pesanan dipindah ke transaksi berlangsung.',
                      );
                    } catch (error) {
                      if (!context.mounted) return;
                      _showMessage(
                        context,
                        error.toString().replaceFirst('Exception: ', ''),
                      );
                    }
                    return;
                  }

                  final shouldCheckout =
                      await _showPaymentConfirmation(context);
                  if (shouldCheckout != true || !context.mounted) {
                    return;
                  }

                  try {
                    final notes = _notesController.text.trim();
                    final transaction = await ref
                        .read(posStateProvider)
                        .checkout(notes: notes.isEmpty ? null : notes);
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
                icon: AppIcon(
                  state.cartContainsNasiPaket
                      ? Icons.pending_actions_rounded
                      : Icons.receipt_long_rounded,
                ),
                label: Text(
                  state.cartContainsNasiPaket
                      ? 'Pindah ke Transaksi Sementara'
                      : 'Mulai Pembayaran',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOngoingTab(BuildContext context, PosAppState state) {
    final selectedId = _selectedPendingTransactionId;
    final selectedPending =
        selectedId == null ? null : state.pendingTransactionById(selectedId);

    if (selectedId != null && selectedPending == null) {
      _selectedPendingTransactionId = null;
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        shellBottomClearance(context),
      ),
      children: [
        if (selectedPending != null)
          _buildPendingDetail(context, state, selectedPending)
        else if (state.pendingTransactions.isEmpty)
          const EmptyState(
            icon: Icons.pending_actions_outlined,
            title: 'Belum ada transaksi berlangsung',
            subtitle: 'Pesanan nasi paket yang dipindah akan muncul di sini.',
          )
        else
          ...state.pendingTransactions.map(
            (pending) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PendingTransactionCard(
                pending: pending,
                onTap: () {
                  setState(() {
                    _selectedPendingTransactionId = pending.id;
                    _pendingCustomerQuery = '';
                    _pendingProductQuery = '';
                    _showPendingProductSuggestions = false;
                    _pendingPaymentMethod = PaymentMethod.cash;
                  });
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPendingDetail(
    BuildContext context,
    PosAppState state,
    PendingTransaction pending,
  ) {
    final productQuery = _pendingProductQuery.trim().toLowerCase();
    final pendingProductIds = {
      for (final item in pending.items) item.productId,
    };
    final filteredProducts =
        productQuery.isEmpty && !_showPendingProductSuggestions
            ? const <Product>[]
            : state.products
                .where((product) {
                  return product.isActive &&
                      (productQuery.isEmpty ||
                          product.name.toLowerCase().contains(productQuery));
                })
                .take(6)
                .toList();
    final customerQuery = _pendingCustomerQuery.trim().toLowerCase();
    final filteredCustomers = state.customers.where((customer) {
      return customer.isActive &&
          (customerQuery.isEmpty ||
              customer.name.toLowerCase().contains(customerQuery) ||
              customer.phone.toLowerCase().contains(customerQuery));
    }).toList();
    final selectedCustomer = pending.customerId == null
        ? null
        : state.customerById(pending.customerId!);
    final needsBonCustomer = _pendingPaymentMethod == PaymentMethod.bon &&
        pending.customerId == null;
    _syncBonCustomerPulse(needsBonCustomer);
    final bonCustomerPulseController = _ensureBonCustomerPulseController();

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Kembali',
                onPressed: () => setState(() {
                  _selectedPendingTransactionId = null;
                  _pendingCustomerQuery = '';
                  _pendingProductQuery = '';
                  _showPendingProductSuggestions = false;
                }),
                icon: const AppIcon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Detail Pesanan Berlangsung',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...pending.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.deepTeal.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        AppMediaPreview(
                          imagePath:
                              state.productById(item.productId)?.imagePath,
                          width: 44,
                          height: 44,
                          borderRadius: 14,
                          label: null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppFormatters.currency(item.sellPrice),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppTheme.foam,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 30,
                                    height: 34,
                                    child: IconButton(
                                      tooltip: 'Kurangi qty',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: item.quantity <= 1 &&
                                              pending.items.length <= 1
                                          ? null
                                          : () async {
                                              try {
                                                await ref
                                                    .read(posStateProvider)
                                                    .decreasePendingTransactionQty(
                                                      pendingTransactionId:
                                                          pending.id,
                                                      productId: item.productId,
                                                    );
                                              } catch (error) {
                                                if (!context.mounted) return;
                                                _showMessage(
                                                  context,
                                                  error.toString().replaceFirst(
                                                      'Exception: ', ''),
                                                );
                                              }
                                            },
                                      icon: const AppIcon(
                                        Icons.remove_rounded,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 24,
                                    child: Text(
                                      '${item.quantity}',
                                      key: Key(
                                          'pending-item-qty-${item.productId}'),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 30,
                                    height: 34,
                                    child: IconButton(
                                      tooltip: 'Tambah qty',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () async {
                                        try {
                                          await ref
                                              .read(posStateProvider)
                                              .increasePendingTransactionQty(
                                                pendingTransactionId:
                                                    pending.id,
                                                productId: item.productId,
                                              );
                                        } catch (error) {
                                          if (!context.mounted) return;
                                          _showMessage(
                                            context,
                                            error.toString().replaceFirst(
                                                'Exception: ', ''),
                                          );
                                        }
                                      },
                                      icon: const AppIcon(
                                        Icons.add_rounded,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              key: Key('pending-item-remove-${item.productId}'),
                              tooltip: 'Hapus produk',
                              style: IconButton.styleFrom(
                                fixedSize: const Size(34, 34),
                                minimumSize: const Size(34, 34),
                                padding: EdgeInsets.zero,
                                foregroundColor: AppTheme.danger,
                                backgroundColor:
                                    AppTheme.danger.withValues(alpha: 0.08),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color:
                                        AppTheme.danger.withValues(alpha: 0.24),
                                  ),
                                ),
                              ),
                              onPressed: pending.items.length <= 1
                                  ? null
                                  : () => _confirmRemovePendingItem(
                                        context,
                                        pending,
                                        item,
                                      ),
                              icon: const AppIcon(
                                Icons.delete_outline_rounded,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        AppFormatters.currency(item.subtotal),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('pending-add-another-product-button'),
              onPressed: () => setState(() {
                _showPendingProductSuggestions = true;
              }),
              icon: const AppIcon(Icons.add_shopping_cart_rounded),
              label: const Text('Tambah Produk Lain'),
            ),
          ),
          const Divider(height: 22),
          const _CashierSectionHeader(
            title: 'Produk Tambahan',
            infoMessage:
                'Cari produk lalu tambahkan ke pesanan berlangsung ini.',
          ),
          const SizedBox(height: 12),
          AppSearchField(
            fieldKey: const Key('pending-product-search'),
            hintText: 'Cari produk untuk pesanan berlangsung',
            onChanged: (value) => setState(() {
              _pendingProductQuery = value;
              _showPendingProductSuggestions = true;
            }),
          ),
          const SizedBox(height: 12),
          if (productQuery.isNotEmpty && filteredProducts.isEmpty)
            const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Produk tidak ditemukan',
              subtitle: 'Coba kata kunci produk lain.',
            )
          else
            ...filteredProducts.map(
              (product) {
                final count = pending.items
                    .where((item) => item.productId == product.id)
                    .fold(0, (sum, item) => sum + item.quantity);
                final isNasiPaket = state.isNasiPaketProduct(product);
                final canAdd = !isNasiPaket || product.isReady;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: pendingProductIds.contains(product.id)
                          ? AppTheme.foam
                          : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppTheme.deepTeal.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        AppMediaPreview(
                          imagePath: product.imagePath,
                          width: 44,
                          height: 44,
                          borderRadius: 14,
                          label: null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppFormatters.currency(product.sellPrice),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 128,
                          child: FilledButton.icon(
                            key: Key('pending-add-product-${product.id}'),
                            onPressed: canAdd
                                ? () async {
                                    try {
                                      await ref
                                          .read(posStateProvider)
                                          .addProductToPendingTransaction(
                                            pendingTransactionId: pending.id,
                                            product: product,
                                          );
                                    } catch (error) {
                                      if (!context.mounted) return;
                                      _showMessage(
                                        context,
                                        error
                                            .toString()
                                            .replaceFirst('Exception: ', ''),
                                      );
                                    }
                                  }
                                : null,
                            icon: const AppIcon(
                              Icons.add_shopping_cart_rounded,
                              size: 18,
                            ),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                canAdd
                                    ? (count > 0 ? 'Tambah ($count)' : 'Tambah')
                                    : 'Kosong',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const Divider(height: 22),
          const _CashierSectionHeader(
            title: 'Pelanggan & Pembayaran',
            infoMessage:
                'Cari atau tambah pelanggan. BON wajib memakai pelanggan aktif.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _BonCustomerSearchPulse(
                  active: needsBonCustomer,
                  animation: bonCustomerPulseController,
                  child: AppSearchField(
                    fieldKey: const Key('pending-customer-search'),
                    hintText: 'Cari pelanggan aktif',
                    showPrefixIcon: false,
                    onChanged: (value) =>
                        setState(() => _pendingCustomerQuery = value),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                key: const Key('pending-customer-add-icon-button'),
                tooltip: 'Daftar pelanggan baru',
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.deepTeal,
                  foregroundColor: Colors.white,
                  fixedSize: const Size(44, 44),
                  minimumSize: const Size(44, 44),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  final customer = await showCustomerFormSheet(
                    context,
                    ref,
                  );
                  if (!mounted || customer == null) return;
                  try {
                    await ref
                        .read(posStateProvider)
                        .setPendingTransactionCustomer(
                          pendingTransactionId: pending.id,
                          customerId: customer.id,
                        );
                    setState(() => _pendingCustomerQuery = '');
                  } catch (error) {
                    if (!context.mounted) return;
                    _showMessage(
                      context,
                      error.toString().replaceFirst('Exception: ', ''),
                    );
                  }
                },
                icon: const AppIcon(Icons.person_add_alt_1_rounded),
              ),
            ],
          ),
          if (needsBonCustomer) ...[
            const SizedBox(height: 8),
            const _BonCustomerNote(),
          ],
          const SizedBox(height: 12),
          if (selectedCustomer != null) ...[
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
                          selectedCustomer.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${selectedCustomer.phone} - ${selectedCustomer.address}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      try {
                        await ref
                            .read(posStateProvider)
                            .setPendingTransactionCustomer(
                              pendingTransactionId: pending.id,
                              customerId: null,
                            );
                        setState(() => _pendingCustomerQuery = '');
                      } catch (error) {
                        if (!context.mounted) return;
                        _showMessage(
                          context,
                          error.toString().replaceFirst('Exception: ', ''),
                        );
                      }
                    },
                    icon: const AppIcon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_pendingCustomerQuery.trim().isNotEmpty &&
              filteredCustomers.isEmpty)
            const EmptyState(
              icon: Icons.people_outline_rounded,
              title: 'Belum ada pelanggan cocok',
              subtitle: 'Tambah pelanggan baru untuk transaksi BON.',
            )
          else if (_pendingCustomerQuery.trim().isNotEmpty)
            ...filteredCustomers.take(5).map(
                  (customer) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () async {
                        try {
                          await ref
                              .read(posStateProvider)
                              .setPendingTransactionCustomer(
                                pendingTransactionId: pending.id,
                                customerId: customer.id,
                              );
                          setState(() => _pendingCustomerQuery = '');
                        } catch (error) {
                          if (!context.mounted) return;
                          _showMessage(
                            context,
                            error.toString().replaceFirst('Exception: ', ''),
                          );
                        }
                      },
                      child: Ink(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: pending.customerId == customer.id
                              ? AppTheme.foam
                              : Colors.white,
                          border: pending.customerId == customer.id
                              ? null
                              : Border.all(
                                  color:
                                      AppTheme.deepTeal.withValues(alpha: 0.08),
                                ),
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
                                    customer.name,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${customer.phone} - ${customer.address}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            if (pending.customerId == customer.id)
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
          SummaryRow(label: 'Total item', value: '${pending.totalQuantity}'),
          SummaryRow(
            label: 'Total',
            value: AppFormatters.currency(pending.totalAmount),
          ),
          if ((pending.notes ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Catatan',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.subtext,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(pending.notes!),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              for (final method in _cashierPaymentMethods) ...[
                Expanded(
                  child: _PaymentMethodButton(
                    key: Key('pending-payment-${method.name}'),
                    label: _cashierPaymentLabel(method),
                    selected: _isCashierPaymentSelected(
                      method,
                      _pendingPaymentMethod,
                    ),
                    onTap: () => setState(() {
                      _pendingPaymentMethod = method == PaymentMethod.qris
                          ? PaymentMethod.qris
                          : method;
                    }),
                  ),
                ),
                if (method != _cashierPaymentMethods.last)
                  const SizedBox(width: 6),
              ],
            ],
          ),
          if (_isCashierPaymentSelected(
            PaymentMethod.qris,
            _pendingPaymentMethod,
          )) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _PaymentMethodButton(
                    key: const Key('pending-payment-noncash-dana'),
                    label: 'E-Wallet',
                    selected: _pendingPaymentMethod == PaymentMethod.qris,
                    onTap: () => setState(
                      () => _pendingPaymentMethod = PaymentMethod.qris,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _PaymentMethodButton(
                    key: const Key('pending-payment-noncash-bank'),
                    label: 'Bank',
                    selected: _pendingPaymentMethod == PaymentMethod.transfer,
                    onTap: () => setState(
                      () => _pendingPaymentMethod = PaymentMethod.transfer,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('pending-start-payment-button'),
              onPressed: () async {
                final shouldCheckout = await _showPendingPaymentConfirmation(
                  context,
                  pending,
                  _pendingPaymentMethod,
                );
                if (shouldCheckout != true || !context.mounted) {
                  return;
                }

                try {
                  final transaction = await ref
                      .read(posStateProvider)
                      .checkoutPendingTransaction(
                        pendingTransactionId: pending.id,
                        paymentMethod: _pendingPaymentMethod,
                      );
                  if (!context.mounted) return;
                  setState(() => _selectedPendingTransactionId = null);
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
              label: const Text('Mulai Pembayaran'),
            ),
          ),
        ],
      ),
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

  Future<void> _confirmRemoveCartItem(
    BuildContext context,
    Product product,
  ) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus dari transaksi?'),
          content: Text(
            '${product.name} akan dihapus dari daftar produk yang akan ditransaksikan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              key: Key('cart-confirm-remove-${product.id}'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true || !context.mounted) {
      return;
    }

    ref.read(posStateProvider).removeFromCart(product.id);
    _showMessage(context, '${product.name} dihapus dari transaksi.');
  }

  Future<void> _confirmRemovePendingItem(
    BuildContext context,
    PendingTransaction pending,
    PendingTransactionItem item,
  ) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus dari transaksi berlangsung?'),
          content: Text(
            '${item.productName} akan dihapus dari pesanan berlangsung ini.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              key: Key('pending-confirm-remove-${item.productId}'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true || !context.mounted) {
      return;
    }

    try {
      await ref.read(posStateProvider).removePendingTransactionItem(
            pendingTransactionId: pending.id,
            productId: item.productId,
          );
      if (!context.mounted) return;
      _showMessage(
        context,
        '${item.productName} dihapus dari transaksi berlangsung.',
      );
    } catch (error) {
      if (!context.mounted) return;
      _showMessage(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<bool?> _showPaymentConfirmation(BuildContext context) async {
    final state = ref.read(posStateProvider);

    if (state.cart.isEmpty) {
      _showMessage(context, 'Pilih produk dari halaman Produk terlebih dulu.');
      return false;
    }

    if (state.selectedPaymentMethod == PaymentMethod.bon &&
        state.selectedCustomerId == null) {
      _showMessage(
        context,
        'Transaksi BON wajib memilih pelanggan terdaftar.',
      );
      return false;
    }

    final notes = _notesController.text.trim();

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          key: const Key('cashier-confirm-payment-dialog'),
          title: const Text('Detail Pesanan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cek lagi item yang diorder sebelum transaksi diselesaikan.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                ...state.cart.entries.map((entry) {
                  final product = state.productById(entry.key);
                  if (product == null) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${product.name} x${entry.value}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppFormatters.currency(
                            product.sellPrice * entry.value,
                          ),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 22),
                _LeftAlignedValueRow(
                  label: 'Pelanggan',
                  value: state.selectedCustomer?.name ?? 'Umum / Tanpa Nama',
                ),
                SummaryRow(
                  label: 'Metode bayar',
                  value: _checkoutPaymentLabel(state.selectedPaymentMethod),
                ),
                SummaryRow(label: 'Total item', value: '${state.cartCount}'),
                SummaryRow(
                  label: 'Total',
                  value: AppFormatters.currency(state.cartTotal),
                ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Catatan',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.subtext,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(notes),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Kembali'),
            ),
            FilledButton(
              key: const Key('cashier-confirm-checkout-button'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Selesaikan Transaksi'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showPendingPaymentConfirmation(
    BuildContext context,
    PendingTransaction pending,
    PaymentMethod paymentMethod,
  ) async {
    if (paymentMethod == PaymentMethod.bon && pending.customerId == null) {
      _showMessage(
        context,
        'Transaksi BON wajib memilih pelanggan terdaftar.',
      );
      return false;
    }

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          key: const Key('pending-confirm-payment-dialog'),
          title: const Text('Detail Pesanan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cek lagi item yang diorder sebelum transaksi diselesaikan.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                ...pending.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.productName} x${item.quantity}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppFormatters.currency(item.subtotal),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 22),
                _LeftAlignedValueRow(
                  label: 'Pelanggan',
                  value: pending.customerName,
                ),
                SummaryRow(
                  label: 'Metode bayar',
                  value: _checkoutPaymentLabel(paymentMethod),
                ),
                SummaryRow(
                    label: 'Total item', value: '${pending.totalQuantity}'),
                SummaryRow(
                  label: 'Total',
                  value: AppFormatters.currency(pending.totalAmount),
                ),
                if ((pending.notes ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Catatan',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.subtext,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(pending.notes!),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Kembali'),
            ),
            FilledButton(
              key: const Key('pending-confirm-checkout-button'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Selesaikan Transaksi'),
            ),
          ],
        );
      },
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
                      value: _checkoutPaymentLabel(transaction.paymentMethod),
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
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  AnimationController _ensureBonCustomerPulseController() {
    return _bonCustomerPulseController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
      lowerBound: 0.25,
      upperBound: 1,
      value: 0.25,
    );
  }

  void _syncBonCustomerPulse(bool active) {
    final controller = _ensureBonCustomerPulseController();

    if (active) {
      if (!controller.isAnimating) {
        controller.repeat(reverse: true, count: 6).whenComplete(() {
          if (mounted) {
            controller.value = 1;
          }
        });
      }
      return;
    }

    if (controller.isAnimating) {
      controller.stop();
    }
    controller.value = 0.25;
  }

  String _cashierPaymentLabel(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.cash => 'Tunai',
      PaymentMethod.bon => 'BON',
      _ => 'Non Tunai',
    };
  }

  String _checkoutPaymentLabel(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.qris => 'E-Wallet',
      PaymentMethod.transfer => 'Bank',
      _ => method.label,
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

class _PendingTransactionCard extends StatelessWidget {
  const _PendingTransactionCard({
    required this.pending,
    required this.onTap,
  });

  final PendingTransaction pending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('pending-transaction-tile-${pending.id}'),
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Ink(
        decoration: AppTheme.frostedDecoration(radius: 28),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const AppIcon(
                Icons.pending_actions_rounded,
                color: AppTheme.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pending.customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pending.totalQuantity} item - ${AppFormatters.dateTime(pending.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppFormatters.currency(pending.totalAmount),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _LeftAlignedValueRow extends StatelessWidget {
  const _LeftAlignedValueRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.start,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _BonCustomerSearchPulse extends StatelessWidget {
  const _BonCustomerSearchPulse({
    required this.active,
    required this.animation,
    required this.child,
  });

  final bool active;
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!active) {
      return child;
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final strength = animation.value;
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppTheme.danger.withValues(alpha: 0.05 * strength),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.danger.withValues(alpha: 0.32 + strength * 0.38),
              width: 1.2 + strength * 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.danger.withValues(alpha: 0.14 * strength),
                blurRadius: 12 + strength * 8,
                spreadRadius: strength * 1.5,
              ),
            ],
          ),
          child: child,
        );
      },
      child: child,
    );
  }
}

class _BonCustomerNote extends StatelessWidget {
  const _BonCustomerNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppIcon(
          Icons.priority_high_rounded,
          color: AppTheme.danger,
          size: 16,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Pilih pelanggan dulu untuk transaksi BON.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.danger,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ],
    );
  }
}

class _CashierTabHeader extends StatelessWidget {
  const _CashierTabHeader({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(76, topInset + 12, 20, 14),
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
        child: TabBar(
          controller: controller,
          tabs: [
            Tab(
              key: Key('cashier-tab-new'),
              text: 'Transaksi Baru',
            ),
            Tab(
              key: Key('cashier-tab-ongoing'),
              text: 'Berlangsung',
            ),
            Tab(
              key: Key('cashier-tab-history'),
              text: 'Riwayat',
            ),
          ],
        ),
      ),
    );
  }
}

class _CashierSectionHeader extends StatelessWidget {
  const _CashierSectionHeader({
    required this.title,
    required this.infoMessage,
  });

  final String title;
  final String infoMessage;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(width: 8),
        _CashierInfoButton(message: infoMessage),
      ],
    );
  }
}

class _CashierInfoButton extends StatefulWidget {
  const _CashierInfoButton({required this.message});

  final String message;

  @override
  State<_CashierInfoButton> createState() => _CashierInfoButtonState();
}

class _CashierInfoButtonState extends State<_CashierInfoButton> {
  final MenuController _controller = MenuController();

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _controller,
      alignmentOffset: const Offset(-246, 8),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(8),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      menuChildren: [
        SizedBox(
          width: 280,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppIcon(
                  Icons.info_outline_rounded,
                  color: AppTheme.deepTeal,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.ink,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    tooltip: 'Tutup',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _controller.close,
                    icon: const AppIcon(Icons.close_rounded, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      builder: (context, controller, child) {
        return IconButton(
          tooltip: 'Lihat penjelasan',
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.deepTeal.withValues(alpha: 0.10),
            foregroundColor: AppTheme.deepTeal,
            fixedSize: const Size(34, 34),
            minimumSize: const Size(34, 34),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: BorderSide(
                color: AppTheme.deepTeal.withValues(alpha: 0.14),
              ),
            ),
          ),
          onPressed: controller.isOpen ? controller.close : controller.open,
          icon: const AppIcon(Icons.info_outline_rounded, size: 20),
        );
      },
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
