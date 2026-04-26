import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/models/app_models.dart';
import '../../shared/state/app_state.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/app_formatters.dart';
import '../../shared/widgets/common_widgets.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posStateProvider);
    final transaction = state.transactionById(transactionId);

    if (transaction == null) {
      return const EmptyState(
        icon: Icons.receipt_long_rounded,
        title: 'Transaksi tidak ditemukan',
        subtitle: 'Buka kembali riwayat transaksi lalu pilih data yang lain.',
      );
    }

    return AppPageScrollView(
      children: [
        HeroPanel(
          badge: StatusChip(
            label: transaction.paymentMethod == PaymentMethod.bon
                ? 'Detail BON'
                : 'Detail transaksi',
            color: Colors.white,
            icon: Icons.receipt_long_rounded,
          ),
          title: transaction.transactionCode,
          subtitle:
              '${transaction.customerName} - ${AppFormatters.dateTime(transaction.createdAt)}',
          trailing: IconButton.filled(
            onPressed: () => context.pop(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.deepTeal,
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          bottom: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              StatusChip(
                label: '${transaction.totalQuantity} qty',
                color: Colors.white,
                icon: Icons.shopping_bag_rounded,
              ),
              StatusChip(
                label: '${transaction.lineItemCount} jenis item',
                color: Colors.white,
                icon: Icons.list_alt_rounded,
              ),
              StatusChip(
                label: transaction.paymentMethod.label,
                color: Colors.white,
                icon: Icons.payments_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.0,
          children: [
            KpiCard(
              title: 'Qty Produk',
              value: '${transaction.totalQuantity}',
              icon: Icons.inventory_2_rounded,
              color: AppTheme.deepTeal,
              subtitle: 'Total kuantitas dalam transaksi',
            ),
            KpiCard(
              title: 'Jenis Item',
              value: '${transaction.lineItemCount}',
              icon: Icons.category_rounded,
              color: AppTheme.info,
              subtitle: 'Jumlah baris item pada struk',
            ),
          ],
        ),
        const SizedBox(height: 20),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Ringkasan Transaksi',
                subtitle:
                    'Metadata utama transaksi yang tersimpan di database.',
              ),
              const SizedBox(height: 12),
              SummaryRow(
                label: 'Kode transaksi',
                value: transaction.transactionCode,
              ),
              SummaryRow(
                label: 'Tanggal',
                value: AppFormatters.dateTime(transaction.createdAt),
              ),
              SummaryRow(label: 'Pelanggan', value: transaction.customerName),
              SummaryRow(
                label: 'Metode bayar',
                value: transaction.paymentMethod.label,
              ),
              SummaryRow(
                label: 'Total transaksi',
                value: AppFormatters.currency(transaction.totalAmount),
              ),
              SummaryRow(
                label: 'Nominal dibayar',
                value: AppFormatters.currency(transaction.amountPaid),
              ),
              SummaryRow(
                label: 'Kembalian',
                value: AppFormatters.currency(transaction.changeAmount),
              ),
              if ((transaction.notes ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.foam,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    transaction.notes!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
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
                title: 'Detail Item',
                subtitle:
                    'Daftar item, qty, harga jual, dan subtotal per item.',
              ),
              const SizedBox(height: 12),
              ...transaction.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TransactionItemCard(item: item),
                ),
              ),
              const Divider(height: 24),
              SummaryRow(
                label: 'Qty total produk',
                value: '${transaction.totalQuantity}',
              ),
              SummaryRow(
                label: 'Jumlah jenis item',
                value: '${transaction.lineItemCount}',
              ),
              SummaryRow(
                label: 'Grand total',
                value: AppFormatters.currency(transaction.totalAmount),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TransactionItemCard extends StatelessWidget {
  const _TransactionItemCard({required this.item});

  final TransactionItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.foam,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: AppTheme.deepTeal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} x ${AppFormatters.currency(item.sellPrice)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppFormatters.currency(item.subtotal),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
