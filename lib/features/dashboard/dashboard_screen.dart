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
      children: [
        _DashboardHero(
          profile: profile,
          greeting: greeting,
          revenue: state.totalRevenue,
          todayTransactions: state.todayTransactionCount,
          onEditProfile: () => showStoreProfileSheet(
            context,
            ref,
            profile: profile,
          ),
          onOpenCashier: () => context.go('/cashier'),
          onOpenReports: () => context.go('/reports'),
        ),
        const SizedBox(height: 18),
        _MetricGrid(
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
        const SizedBox(height: 20),
        _QuickCommandPanel(
          onCashierTap: () => context.go('/cashier'),
          onProductTap: () => context.go('/products'),
          onCustomerTap: () => context.go('/customers'),
          onAnalyticsTap: () => context.go('/analytics'),
        ),
        const SizedBox(height: 20),
        _OperationFocusSection(
          activeDebts: activeDebts,
          lowStockProducts: lowStockProducts,
          onOpenDebts: () => context.go('/debts'),
          onOpenInventory: () => context.go('/inventory'),
          onOpenDebt: (debt) => context.go('/debts/${debt.id}'),
        ),
        const SizedBox(height: 20),
        _RecentTransactionsSection(
          transactions: recentTransactions,
          onOpenCashier: () => context.go('/cashier'),
        ),
      ],
    );
  }

  _GreetingData _greetingFor(DateTime now) {
    if (now.hour < 11) {
      return const _GreetingData(
        label: 'Selamat pagi',
        icon: Icons.wb_sunny_rounded,
      );
    }
    if (now.hour < 15) {
      return const _GreetingData(
        label: 'Selamat siang',
        icon: Icons.light_mode_rounded,
      );
    }
    if (now.hour < 18) {
      return const _GreetingData(
        label: 'Selamat sore',
        icon: Icons.wb_twilight_rounded,
      );
    }
    return const _GreetingData(
      label: 'Selamat malam',
      icon: Icons.nights_stay_rounded,
    );
  }
}

class _GreetingData {
  const _GreetingData({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.profile,
    required this.greeting,
    required this.revenue,
    required this.todayTransactions,
    required this.onEditProfile,
    required this.onOpenCashier,
    required this.onOpenReports,
  });

  final AppProfile profile;
  final _GreetingData greeting;
  final double revenue;
  final int todayTransactions;
  final VoidCallback onEditProfile;
  final VoidCallback onOpenCashier;
  final VoidCallback onOpenReports;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF12343B),
            Color(0xFF1D6B72),
            Color(0xFFEDC56F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0, 0.62, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.midnight.withValues(alpha: 0.20),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            StatusChip(
                              label: greeting.label,
                              color: Colors.white,
                              icon: greeting.icon,
                              iconColor: const Color(0xFFFFD54F),
                            ),
                            StatusChip(
                              label: profile.ownerName ?? 'Pemilik toko',
                              color: const Color(0xFFFFE5A8),
                              icon: Icons.workspace_premium_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          profile.storeName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          profile.storeSubtitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      AppProfileAvatar(photoPath: profile.photoPath, size: 76),
                      const SizedBox(height: 10),
                      IconButton.filled(
                        key: const Key('dashboard-edit-profile-button'),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.deepTeal,
                        ),
                        tooltip: 'Edit profil toko',
                        onPressed: onEditProfile,
                        icon: const Icon(Icons.edit_rounded),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _HeroPill(
                    icon: Icons.trending_up_rounded,
                    label: 'Revenue',
                    value: AppFormatters.currency(revenue),
                  ),
                  _HeroPill(
                    icon: Icons.bolt_rounded,
                    label: 'Hari ini',
                    value: '$todayTransactions transaksi',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 390;
                  final children = [
                    FilledButton.icon(
                      onPressed: onOpenCashier,
                      icon: const Icon(Icons.point_of_sale_rounded),
                      label: const Text('Buka kasir'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.26),
                        ),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: onOpenReports,
                      icon: const Icon(Icons.bar_chart_rounded),
                      label: const Text('Laporan'),
                    ),
                  ];

                  if (compact) {
                    return Column(
                      children: [
                        for (var index = 0; index < children.length; index++)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: index == children.length - 1 ? 0 : 10,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: children[index],
                            ),
                          ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      for (var index = 0; index < children.length; index++) ...[
                        Expanded(child: children[index]),
                        if (index != children.length - 1)
                          const SizedBox(width: 12),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 142),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
          ),
        ],
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
        final ratio = constraints.maxWidth < 370 ? 0.82 : 0.94;

        return GridView.builder(
          padding: EdgeInsets.zero,
          itemCount: metrics.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: metric.color.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.midnight.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(metric.icon, color: metric.color),
          ),
          const Spacer(),
          Text(
            metric.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              metric.value,
              maxLines: 1,
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 6),
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
              icon: const Icon(Icons.widgets_rounded),
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 520;
              final width =
                  twoColumns ? (constraints.maxWidth - 12) / 2 : double.infinity;
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
              child: Icon(data.icon, color: Colors.white),
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
            Icon(
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
                child: const Icon(
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
            for (final product in products)
              _StockListTile(product: product),
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
              child: Icon(
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
            child: Icon(icon, color: AppTheme.deepTeal),
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
