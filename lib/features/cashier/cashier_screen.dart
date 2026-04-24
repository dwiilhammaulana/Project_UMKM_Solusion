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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(
          title: 'Kasir',
          subtitle:
              'Pilih produk, tentukan pelanggan, lalu simulasikan pembayaran tunai atau BON.',
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: '1. Pilih Produk'),
              const SizedBox(height: 12),
              TextField(
                key: const Key('cashier-product-search'),
                onChanged: (value) => setState(() => _productQuery = value),
                decoration: const InputDecoration(
                  hintText: 'Cari menu kopi atau makanan',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Semua'),
                      selected: _categoryId == null,
                      onSelected: (_) => setState(() => _categoryId = null),
                    ),
                    const SizedBox(width: 8),
                    ...state.categories.map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category.name),
                          selected: _categoryId == category.id,
                          onSelected: (_) =>
                              setState(() => _categoryId = category.id),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
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
                    onAdd: () => ref.read(posStateProvider).addToCart(product),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: '2. Keranjang'),
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
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(product.name),
                    subtitle: Text(AppFormatters.currency(product.sellPrice)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => ref
                              .read(posStateProvider)
                              .decreaseCartQty(product.id),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '${entry.value}',
                          key: Key('cart-qty-${product.id}'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          onPressed: () => ref
                              .read(posStateProvider)
                              .increaseCartQty(product.id),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(),
                SummaryRow(label: 'Total item', value: '${state.cartCount}'),
                SummaryRow(
                  label: 'Total belanja',
                  value: AppFormatters.currency(state.cartTotal),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: '3. Pilih Pelanggan',
                subtitle:
                    'Transaksi BON wajib memakai pelanggan terdaftar, tidak bisa Umum.',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      key: const Key('customer-general-chip'),
                      label: const Text('Umum / Tanpa Nama'),
                      selected: state.selectedCustomerId == null,
                      onSelected: (_) {
                        if (state.selectedPaymentMethod == PaymentMethod.bon) {
                          _showMessage(
                            context,
                            'Transaksi BON wajib memilih pelanggan terdaftar.',
                          );
                          return;
                        }
                        ref.read(posStateProvider).setSelectedCustomer(null);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
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
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Daftar Baru'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('cashier-customer-search'),
                onChanged: (value) => setState(() => _customerQuery = value),
                decoration: const InputDecoration(
                  hintText: 'Cari pelanggan',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              ...filteredCustomers.take(5).map(
                    (customer) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(customer.name),
                        subtitle: Text(
                          '${customer.phone} - ${customer.address}',
                        ),
                        trailing: state.selectedCustomerId == customer.id
                            ? const Icon(
                                Icons.check_circle,
                                color: AppTheme.success,
                              )
                            : null,
                        onTap: () => ref
                            .read(posStateProvider)
                            .setSelectedCustomer(customer.id),
                      ),
                    ),
                  ),
              if (state.selectedCustomer != null) ...[
                const SizedBox(height: 8),
                StatusChip(
                  label: 'Terpilih: ${state.selectedCustomer!.name}',
                  color: AppTheme.success,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: '4. Metode Pembayaran'),
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
                    color: AppTheme.warning.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(18),
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
              const SizedBox(height: 16),
              ElevatedButton.icon(
                key: const Key('cashier-checkout-button'),
                onPressed: () async {
                  try {
                    final transaction = await ref
                        .read(posStateProvider)
                        .checkout(
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
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Material(
            borderRadius: BorderRadius.circular(28),
            color: AppTheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.paymentMethod == PaymentMethod.bon
                        ? 'Transaksi BON Tersimpan'
                        : 'Transaksi Berhasil',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${transaction.transactionCode} - ${AppFormatters.dateTime(transaction.createdAt)}',
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.mist,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SummaryRow(
                          label: 'Pelanggan',
                          value: transaction.customerName,
                        ),
                        SummaryRow(
                          label: 'Metode bayar',
                          value: transaction.paymentMethod.label,
                        ),
                        SummaryRow(
                          label: 'Total',
                          value: AppFormatters.currency(
                            transaction.totalAmount,
                          ),
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
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            if (transaction.paymentMethod ==
                                PaymentMethod.bon) {
                              this.context.go('/debts');
                            }
                          },
                          child: Text(
                            transaction.paymentMethod == PaymentMethod.bon
                                ? 'Buka Bon'
                                : 'Selesai',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
