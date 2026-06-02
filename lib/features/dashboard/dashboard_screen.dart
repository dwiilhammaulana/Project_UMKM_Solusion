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
    final lowStockProducts = state.lowStockProducts.take(3).toList();
    final recentTransactions = state.transactions.take(4).toList();
    final greeting = _greetingFor(DateTime.now());

    return AppPageScrollView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
      children: [
        _DashboardHero(
          profile: profile,
          greeting: greeting,
          onEditProfile: () => showStoreProfileSheet(
            context,
            ref,
            profile: profile,
          ),
          onOpenCashier: () => context.go('/cashier'),
          onOpenReports: () => context.go('/reports'),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _MetricGrid(
            metrics: [
              _MetricData(
                title: 'Pendapatan',
                value: AppFormatters.currency(state.totalRevenue),
                subtitle: 'Termasuk cicilan masuk',
                icon: Icons.payments_rounded,
                color: AppTheme.deepTeal,
              ),
              _MetricData(
                title: 'Transaksi Hari Ini',
                value: '${state.todayTransactionCount}',
                subtitle: 'Aktivitas penjualan',
                icon: Icons.receipt_long_rounded,
                color: AppTheme.info,
              ),
              _MetricData(
                title: 'Bon Aktif',
                value: AppFormatters.currency(state.activeDebtTotal),
                subtitle: '${state.activeDebtsSorted.length} belum lunas',
                icon: Icons.account_balance_wallet_rounded,
                color: AppTheme.warning,
              ),
              _MetricData(
                title: 'Stok Menipis',
                value: '${state.lowStockProducts.length} item',
                subtitle: 'Siapkan restock',
                icon: Icons.inventory_2_rounded,
                color: AppTheme.success,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _QuickCommandPanel(
            onCashierTap: () => context.go('/cashier'),
            onProductTap: () => context.go('/products'),
            onCustomerTap: () => context.go('/customers'),
            onAnalyticsTap: () => context.go('/analytics'),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _OperationFocusSection(
            activeDebts: activeDebts,
            lowStockProducts: lowStockProducts,
            onOpenDebts: () => context.go('/debts'),
            onOpenInventory: () => context.go('/inventory'),
            onOpenDebt: (debt) => context.go('/debts/${debt.id}'),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _RecentTransactionsSection(
            transactions: recentTransactions,
            onOpenCashier: () => context.go('/cashier'),
          ),
        ),
      ],
    );
  }

  String _greetingFor(DateTime now) {
    if (now.hour < 11) {
      return 'Selamat Pagi';
    }
    if (now.hour < 15) {
      return 'Selamat Siang';
    }
    if (now.hour < 18) {
      return 'Selamat Sore';
    }
    return 'Selamat Malam';
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.profile,
    required this.greeting,
    required this.onEditProfile,
    required this.onOpenCashier,
    required this.onOpenReports,
  });

  final AppProfile profile;
  final String greeting;
  final VoidCallback onEditProfile;
  final VoidCallback onOpenCashier;
  final VoidCallback onOpenReports;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final heroHeight = (screenHeight * 0.57).clamp(390.0, 540.0);

    return SizedBox(
      height: heroHeight,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppTheme.deepTeal,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(46),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.midnight.withValues(alpha: 0.22),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'landing_page.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppTheme.deepTeal.withValues(alpha: 0.70),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(30, topInset + 42, 30, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$greeting,',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile.storeName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      _ProfileEditAvatar(
                        photoPath: profile.photoPath,
                        onEditProfile: onEditProfile,
                      ),
                    ],
                  ),
                  const Spacer(),
                  _HeroButton(
                    label: 'Buka kasir',
                    onPressed: onOpenCashier,
                    filled: true,
                  ),
                  const SizedBox(height: 14),
                  _HeroButton(
                    label: 'Laporan',
                    onPressed: onOpenReports,
                    filled: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileEditAvatar extends StatelessWidget {
  const _ProfileEditAvatar({
    required this.photoPath,
    required this.onEditProfile,
  });

  final String? photoPath;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Edit profil toko',
      child: Material(
        key: const Key('dashboard-edit-profile-button'),
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onEditProfile,
          child: AppProfileAvatar(photoPath: photoPath, size: 84),
        ),
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.label,
    required this.onPressed,
    required this.filled,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final background = filled ? Colors.white : Colors.transparent;
    final foreground = filled ? AppTheme.deepTeal : Colors.white;

    return SizedBox(
      width: double.infinity,
      height: 66,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.94),
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        final ratio = constraints.maxWidth >= 720 ? 0.86 : 0.78;

        return GridView.builder(
          padding: EdgeInsets.zero,
          itemCount: metrics.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: ratio,
          ),
          itemBuilder: (context, index) {
            return _MetricCard(metric: metrics[index]);
          },
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.deepTeal.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.midnight.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(metric.icon, color: metric.color, size: 34),
          const Spacer(),
          Text(
            metric.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              metric.value,
              maxLines: 1,
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            metric.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _QuickCommandPanel extends StatelessWidget {
  const _QuickCommandPanel({
    required this.onCashierTap,
    required this.onProductTap,
    required this.onCustomerTap,
    required this.onAnalyticsTap,
  });

  final VoidCallback onCashierTap;
  final VoidCallback onProductTap;
  final VoidCallback onCustomerTap;
  final VoidCallback onAnalyticsTap;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Aksi Cepat',
            subtitle: 'Alur utama toko dalam satu layar.',
            action: IconButton.filledTonal(
              tooltip: 'Buka modul lain',
              onPressed: () => context.go('/more'),
              icon: const AppIcon(Icons.widgets_rounded),
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 520;
              final width = twoColumns
                  ? (constraints.maxWidth - 12) / 2
                  : double.infinity;
              final actions = [
                _CommandData(
                  icon: Icons.point_of_sale_rounded,
                  title: 'Kasir Baru',
                  subtitle: 'Input pesanan',
                  color: AppTheme.deepTeal,
                  onTap: onCashierTap,
                ),
                _CommandData(
                  icon: Icons.add_box_rounded,
                  title: 'Produk',
                  subtitle: 'Harga dan stok',
                  color: const Color(0xFFEF8D5C),
                  onTap: onProductTap,
                ),
                _CommandData(
                  icon: Icons.groups_rounded,
                  title: 'Pelanggan',
                  subtitle: 'Relasi dan bon',
                  color: AppTheme.info,
                  onTap: onCustomerTap,
                ),
                _CommandData(
                  icon: Icons.insights_rounded,
                  title: 'Analitik',
                  subtitle: 'Pola penjualan',
                  color: AppTheme.success,
                  onTap: onAnalyticsTap,
                ),
              ];

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final action in actions)
                    SizedBox(
                      width: width,
                      child: _CommandTile(data: action),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CommandData {
  const _CommandData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
}

class _CommandTile extends StatelessWidget {
  const _CommandTile({required this.data});

  final _CommandData data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: data.onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: data.color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: data.color.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: data.color,
                borderRadius: BorderRadius.circular(17),
              ),
              child: AppIcon(data.icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            AppIcon(
              Icons.arrow_forward_rounded,
              color: data.color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _OperationFocusSection extends StatelessWidget {
  const _OperationFocusSection({
    required this.activeDebts,
    required this.lowStockProducts,
    required this.onOpenDebts,
    required this.onOpenInventory,
    required this.onOpenDebt,
  });

  final List<DebtRecord> activeDebts;
  final List<Product> lowStockProducts;
  final VoidCallback onOpenDebts;
  final VoidCallback onOpenInventory;
  final ValueChanged<DebtRecord> onOpenDebt;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final children = [
          _DebtFocusCard(
            debts: activeDebts,
            onOpenDebts: onOpenDebts,
            onOpenDebt: onOpenDebt,
          ),
          _StockFocusCard(
            products: lowStockProducts,
            onOpenInventory: onOpenInventory,
          ),
        ];

        if (!wide) {
          return Column(
            children: [
              children[0],
              const SizedBox(height: 14),
              children[1],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: children[0]),
            const SizedBox(width: 14),
            Expanded(child: children[1]),
          ],
        );
      },
    );
  }
}

class _DebtFocusCard extends StatelessWidget {
  const _DebtFocusCard({
    required this.debts,
    required this.onOpenDebts,
    required this.onOpenDebt,
  });

  final List<DebtRecord> debts;
  final VoidCallback onOpenDebts;
  final ValueChanged<DebtRecord> onOpenDebt;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Bon Prioritas',
            subtitle: 'Pelanggan yang perlu ditagih lebih dulu.',
            action: TextButton(
              onPressed: onOpenDebts,
              child: const Text('Semua'),
            ),
          ),
          const SizedBox(height: 12),
          if (debts.isEmpty)
            const _InlineEmptyState(
              icon: Icons.verified_rounded,
              title: 'Semua bon lunas',
              subtitle: 'Tidak ada utang aktif saat ini.',
            )
          else
            for (final debt in debts)
              _DebtListTile(
                debt: debt,
                onTap: () => onOpenDebt(debt),
              ),
        ],
      ),
    );
  }
}

class _DebtListTile extends StatelessWidget {
  const _DebtListTile({
    required this.debt,
    required this.onTap,
  });

  final DebtRecord debt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.warning.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const AppIcon(
                  Icons.wallet_rounded,
                  color: AppTheme.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sisa ${AppFormatters.currency(debt.remainingAmount)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 96),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: DebtAgeIndicator(ageInDays: debt.ageInDays),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockFocusCard extends StatelessWidget {
  const _StockFocusCard({
    required this.products,
    required this.onOpenInventory,
  });

  final List<Product> products;
  final VoidCallback onOpenInventory;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Stok Siaga',
            subtitle: 'Item menipis yang perlu cepat dicek.',
            action: TextButton(
              onPressed: onOpenInventory,
              child: const Text('Inventori'),
            ),
          ),
          const SizedBox(height: 12),
          if (products.isEmpty)
            const _InlineEmptyState(
              icon: Icons.inventory_rounded,
              title: 'Stok aman',
              subtitle: 'Tidak ada produk di bawah batas minimum.',
            )
          else
            for (final product in products) _StockListTile(product: product),
        ],
      ),
    );
  }
}

class _StockListTile extends StatelessWidget {
  const _StockListTile({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            AppMediaPreview(
              imagePath: product.imagePath,
              width: 42,
              height: 42,
              borderRadius: 15,
              placeholderIcon: Icons.local_cafe_rounded,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sisa ${product.stockQty} ${product.unit} - min ${product.minStock}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            StatusChip(
              label: 'Restock',
              color: AppTheme.success,
              icon: Icons.trending_up_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTransactionsSection extends StatelessWidget {
  const _RecentTransactionsSection({
    required this.transactions,
    required this.onOpenCashier,
  });

  final List<TransactionRecord> transactions;
  final VoidCallback onOpenCashier;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Transaksi Terbaru',
            subtitle: 'Penjualan yang baru masuk.',
            action: TextButton(
              onPressed: onOpenCashier,
              child: const Text('Kasir'),
            ),
          ),
          const SizedBox(height: 12),
          if (transactions.isEmpty)
            const _InlineEmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'Belum ada transaksi',
              subtitle: 'Mulai transaksi pertama dari halaman kasir.',
            )
          else
            for (final transaction in transactions)
              _TransactionListTile(transaction: transaction),
        ],
      ),
    );
  }
}

class _TransactionListTile extends StatelessWidget {
  const _TransactionListTile({required this.transaction});

  final TransactionRecord transaction;

  @override
  Widget build(BuildContext context) {
    final isDebt = transaction.paymentMethod == PaymentMethod.bon;
    final color = isDebt ? AppTheme.warning : AppTheme.deepTeal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(16),
              ),
              child: AppIcon(
                isDebt ? Icons.schedule_rounded : Icons.shopping_bag_rounded,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${transaction.transactionCode} - ${transaction.paymentMethod.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                AppFormatters.currency(transaction.totalAmount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({
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
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.foam.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.deepTeal.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.84),
              borderRadius: BorderRadius.circular(20),
            ),
            child: AppIcon(icon, color: AppTheme.deepTeal),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
