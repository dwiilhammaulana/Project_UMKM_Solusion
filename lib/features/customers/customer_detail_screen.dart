import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/models/app_models.dart';
import '../../shared/state/app_state.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/app_formatters.dart';
import '../../shared/widgets/common_widgets.dart';

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posStateProvider);
    final matches = state.customers.where((customer) => customer.id == customerId);
    if (matches.isEmpty) {
      return const EmptyState(
        icon: Icons.person_search_rounded,
        title: 'Pelanggan tidak ditemukan',
        subtitle: 'Coba kembali ke daftar pelanggan dan pilih data lain.',
      );
    }

    final customer = matches.first;
    final transactions = state.transactionsByCustomer(customerId);
    final debts = state.debtsByCustomer(customerId);
    final payments = state.paymentsByCustomer(customerId);

    return AppPageScrollView(
      children: [
        HeroPanel(
          badge: StatusChip(
            label: customer.isActive ? 'Pelanggan aktif' : 'Pelanggan nonaktif',
            color: Colors.white,
            icon: Icons.person_outline_rounded,
          ),
          title: customer.name,
          subtitle: '${customer.phone} · ${customer.address}',
          trailing: Column(
            children: [
              IconButton.filled(
                onPressed: () => context.pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.deepTeal,
                ),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(height: 12),
              const AppMediaPreview(
                width: 68,
                height: 68,
                borderRadius: 34,
                placeholderIcon: Icons.person_outline_rounded,
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
          childAspectRatio: 1.05,
          children: [
            KpiCard(
              title: 'Total Belanja',
              value: AppFormatters.currency(state.totalPurchaseByCustomer(customerId)),
              icon: Icons.shopping_cart_rounded,
              color: AppTheme.info,
            ),
            KpiCard(
              title: 'Utang Aktif',
              value: AppFormatters.currency(state.activeDebtByCustomer(customerId)),
              icon: Icons.account_balance_wallet_rounded,
              color: AppTheme.warning,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildHistoryCard(
          context,
          title: 'Riwayat Transaksi',
          emptyIcon: Icons.receipt_long_rounded,
          emptyTitle: 'Belum ada transaksi',
          emptySubtitle: 'Transaksi pelanggan akan muncul di sini.',
          items: transactions
              .map(
                (transaction) => _HistoryTile(
                  title: transaction.transactionCode,
                  subtitle:
                      '${AppFormatters.dateTime(transaction.createdAt)} · ${transaction.paymentMethod.label}',
                  trailing: AppFormatters.currency(transaction.totalAmount),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        _buildHistoryCard(
          context,
          title: 'Riwayat Bon',
          emptyIcon: Icons.credit_score_rounded,
          emptyTitle: 'Tidak ada bon',
          emptySubtitle: 'Data bon pelanggan akan muncul jika pernah transaksi BON.',
          items: debts
              .map(
                (debt) => _HistoryTile(
                  title: AppFormatters.currency(debt.originalAmount),
                  subtitle:
                      '${debt.status.label} · ${AppFormatters.date(debt.createdAt)}',
                  trailing: AppFormatters.currency(debt.remainingAmount),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        _buildHistoryCard(
          context,
          title: 'Riwayat Pembayaran Bon',
          emptyIcon: Icons.payments_outlined,
          emptyTitle: 'Belum ada pembayaran',
          emptySubtitle: 'Cicilan dan pelunasan bon pelanggan akan tampil di sini.',
          items: payments
              .map(
                (payment) => _HistoryTile(
                  title: AppFormatters.currency(payment.amount),
                  subtitle:
                      '${payment.paymentMethod.label} · ${AppFormatters.dateTime(payment.paidAt)}',
                  trailing: '',
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(
    BuildContext context, {
    required String title,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
    required List<_HistoryTile> items,
  }) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title),
          const SizedBox(height: 12),
          if (items.isEmpty)
            EmptyState(
              icon: emptyIcon,
              title: emptyTitle,
              subtitle: emptySubtitle,
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(item.subtitle, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      if (item.trailing.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Text(
                          item.trailing,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryTile {
  const _HistoryTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final String trailing;
}
