import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/models/app_models.dart';
import '../../shared/state/app_state.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/app_formatters.dart';
import '../../shared/widgets/common_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posStateProvider);
    final activeDebts = state.activeDebtsSorted.take(3).toList();
    final recentTransactions = state.transactions.take(4).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(
          title: 'Warung Kopi Pertigaan Jati',
          subtitle:
              'Pantau transaksi, bon pelanggan, dan stok menipis dari satu dashboard Android.',
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.15,
          children: [
            KpiCard(
              title: 'Pendapatan Tercatat',
              value: AppFormatters.currency(state.totalRevenue),
              icon: Icons.payments_rounded,
              color: AppTheme.forest,
              subtitle: 'Termasuk cicilan bon yang sudah dibayar',
            ),
            KpiCard(
              title: 'Transaksi Hari Ini',
              value: '${state.todayTransactionCount}',
              icon: Icons.receipt_long_rounded,
              color: AppTheme.pine,
              subtitle: 'Dummy data aktif dalam satu sesi aplikasi',
            ),
            KpiCard(
              title: 'Bon Aktif',
              value: AppFormatters.currency(state.activeDebtTotal),
              icon: Icons.account_balance_wallet_rounded,
              color: AppTheme.moss,
              subtitle: '${state.activeDebtsSorted.length} bon belum lunas',
            ),
            KpiCard(
              title: 'Stok Menipis',
              value: '${state.lowStockProducts.length} item',
              icon: Icons.warning_amber_rounded,
              color: AppTheme.warning,
              subtitle: 'Prioritas restock untuk shift berikutnya',
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Aksi Cepat',
                subtitle:
                    'Shortcut untuk pekerjaan yang paling sering dipakai.',
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _QuickActionButton(
                    label: 'Mulai Kasir',
                    icon: Icons.point_of_sale_rounded,
                    onTap: () => context.go('/cashier'),
                  ),
                  _QuickActionButton(
                    label: 'Tambah Pelanggan',
                    icon: Icons.person_add_alt_1_rounded,
                    onTap: () => context.go('/customers'),
                  ),
                  _QuickActionButton(
                    label: 'Bayar Bon',
                    icon: Icons.paid_rounded,
                    onTap: () => context.go('/debts'),
                  ),
                  _QuickActionButton(
                    label: 'Cek Stok',
                    icon: Icons.inventory_2_rounded,
                    onTap: () => context.go('/inventory'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Bon Belum Lunas',
                subtitle: 'Tiga pelanggan paling lama belum bayar.',
                action: TextButton(
                  onPressed: () => context.go('/debts'),
                  child: const Text('Lihat semua'),
                ),
              ),
              const SizedBox(height: 12),
              if (activeDebts.isEmpty)
                const EmptyState(
                  icon: Icons.verified_rounded,
                  title: 'Semua bon lunas',
                  subtitle: 'Belum ada pelanggan yang memiliki utang aktif.',
                )
              else
                ...activeDebts.map(
                  (debt) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      title: Text(debt.customerName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          DebtAgeIndicator(ageInDays: debt.ageInDays),
                          const SizedBox(height: 8),
                          Text(
                            'Sisa ${AppFormatters.currency(debt.remainingAmount)}',
                          ),
                        ],
                      ),
                      trailing: IconButton.filledTonal(
                        onPressed: () async {
                          await ref.read(posStateProvider).markDebtPaid(debt.id);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Bon ${debt.customerName} ditandai lunas.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.done_all_rounded),
                      ),
                      onTap: () => context.go('/debts/${debt.id}'),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Stok Perlu Perhatian',
                subtitle: 'Produk yang sudah menyentuh batas minimum.',
                action: TextButton(
                  onPressed: () => context.go('/inventory'),
                  child: const Text('Buka stok'),
                ),
              ),
              const SizedBox(height: 12),
              ...state.lowStockProducts.take(4).map(
                    (product) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(product.name),
                      subtitle: Text(
                        'Stok ${product.stockQty} ${product.unit} - Min ${product.minStock}',
                      ),
                      trailing: const StatusChip(
                        label: 'Low',
                        color: AppTheme.warning,
                      ),
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Transaksi Terbaru',
                subtitle: 'Preview transaksi yang baru masuk ke sistem dummy.',
              ),
              const SizedBox(height: 12),
              ...recentTransactions.map(
                (transaction) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.mist,
                    child: Icon(
                      transaction.paymentMethod.label == 'BON'
                          ? Icons.schedule_rounded
                          : Icons.shopping_bag_rounded,
                      color: AppTheme.forest,
                    ),
                  ),
                  title: Text(transaction.customerName),
                  subtitle: Text(
                    '${transaction.transactionCode} - ${transaction.paymentMethod.label}',
                  ),
                  trailing: Text(
                    AppFormatters.currency(transaction.totalAmount),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}
