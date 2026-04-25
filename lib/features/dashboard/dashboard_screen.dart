import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/models/app_models.dart';
import '../../shared/state/app_state.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/app_formatters.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/store_profile_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posStateProvider);
    final profile = state.appProfile;
    final activeDebts = state.activeDebtsSorted.take(3).toList();
    final recentTransactions = state.transactions.take(4).toList();

    return AppPageScrollView(
      children: [
        HeroPanel(
          badge: StatusChip(
            label: profile.ownerName ?? 'Pemilik toko',
            color: Colors.white,
            icon: Icons.waving_hand_rounded,
          ),
          title: profile.storeName,
          subtitle: profile.storeSubtitle,
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppProfileAvatar(photoPath: profile.photoPath),
              const SizedBox(height: 12),
              IconButton.filled(
                key: const Key('dashboard-edit-profile-button'),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.deepTeal,
                ),
                onPressed: () => showStoreProfileSheet(
                  context,
                  ref,
                  profile: profile,
                ),
                icon: const Icon(Icons.edit_rounded),
              ),
            ],
          ),
          bottom: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.go('/cashier'),
                  icon: const Icon(Icons.point_of_sale_rounded),
                  label: const Text('Buka kasir'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.20),
                    ),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => context.go('/more'),
                  icon: const Icon(Icons.grid_view_rounded),
                  label: const Text('Modul lain'),
                ),
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
          childAspectRatio: 0.95,
          children: [
            KpiCard(
              title: 'Pendapatan',
              value: AppFormatters.currency(state.totalRevenue),
              icon: Icons.payments_rounded,
              color: AppTheme.deepTeal,
              subtitle: 'Termasuk pembayaran cicilan',
            ),
            KpiCard(
              title: 'Transaksi Hari Ini',
              value: '${state.todayTransactionCount}',
              icon: Icons.receipt_long_rounded,
              color: AppTheme.info,
              subtitle: 'Aktivitas terbaru di aplikasi',
            ),
            KpiCard(
              title: 'Bon Aktif',
              value: AppFormatters.currency(state.activeDebtTotal),
              icon: Icons.account_balance_wallet_rounded,
              color: AppTheme.warning,
              subtitle: '${state.activeDebtsSorted.length} bon belum lunas',
            ),
            KpiCard(
              title: 'Stok Menipis',
              value: '${state.lowStockProducts.length} item',
              icon: Icons.warning_amber_rounded,
              color: AppTheme.success,
              subtitle: 'Perlu restock segera',
            ),
          ],
        ),
        const SizedBox(height: 20),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Aksi Cepat',
                subtitle: 'Buka alur yang paling sering dipakai dalam satu tap.',
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Expanded(
                    child: _QuickActionInfo(
                      icon: Icons.flash_on_rounded,
                      title: 'Kasir Cepat',
                      subtitle: 'Transaksi dan checkout',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionInfo(
                      icon: Icons.inventory_2_rounded,
                      title: 'Cek Stok',
                      subtitle: 'Monitor item menipis',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppActionTile(
                icon: Icons.person_add_alt_1_rounded,
                title: 'Kelola profil toko',
                subtitle: 'Upload foto profil toko dan ubah identitas tampilan.',
                onTap: () => showStoreProfileSheet(
                  context,
                  ref,
                  profile: profile,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Bon Prioritas',
                subtitle: 'Utang aktif yang butuh perhatian lebih dulu.',
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
                  (debt) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppMenuLinkTile(
                      icon: Icons.wallet_rounded,
                      title: debt.customerName,
                      subtitle:
                          'Sisa ${AppFormatters.currency(debt.remainingAmount)}',
                      trailing: DebtAgeIndicator(ageInDays: debt.ageInDays),
                      onTap: () => context.go('/debts/${debt.id}'),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Transaksi Terbaru',
                subtitle: 'Preview aktivitas penjualan yang baru masuk.',
                action: TextButton(
                  onPressed: () => context.go('/cashier'),
                  child: const Text('Buka kasir'),
                ),
              ),
              const SizedBox(height: 12),
              ...recentTransactions.map(
                (transaction) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.foam,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            transaction.paymentMethod.name == 'bon'
                                ? Icons.schedule_rounded
                                : Icons.shopping_bag_rounded,
                            color: AppTheme.deepTeal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction.customerName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${transaction.transactionCode} · ${transaction.paymentMethod.label}',
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

class _QuickActionInfo extends StatelessWidget {
  const _QuickActionInfo({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.foam,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.deepTeal),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
