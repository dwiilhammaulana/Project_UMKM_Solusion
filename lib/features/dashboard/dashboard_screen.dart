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
          child: _OperationFocusSection(
            activeDebts: activeDebts,
            lowStockProducts: lowStockProducts,
            onOpenDebts: () => context.go('/debts'),
            onOpenInventory: () => context.go('/inventory'),
            onOpenDebt: (debt) => context.go('/debts/${debt.id}'),
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
              padding: EdgeInsets.fromLTRB(18, topInset + 22, 24, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AppProfileEditAvatar(
                        key: const Key('dashboard-edit-profile-button'),
                        photoPath: profile.photoPath,
                        onEditProfile: onEditProfile,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.86),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'di toko ',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    height: 1.04,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    profile.storeName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      height: 1.04,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const _DashboardHeroLogo(),
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

class _DashboardHeroLogo extends StatelessWidget {
  const _DashboardHeroLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: 82,
      child: Align(
        alignment: Alignment.centerRight,
        child: Image.asset(
          'logo_putih.png',
          height: 34,
          fit: BoxFit.contain,
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
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DebtFocusContent(
            debts: activeDebts,
            onOpenDebts: onOpenDebts,
            onOpenDebt: onOpenDebt,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppTheme.deepTeal.withValues(alpha: 0.10),
            ),
          ),
          _StockFocusContent(
            products: lowStockProducts,
            onOpenInventory: onOpenInventory,
          ),
        ],
      ),
    );
  }
}

class _DebtFocusContent extends StatelessWidget {
  const _DebtFocusContent({
    required this.debts,
    required this.onOpenDebts,
    required this.onOpenDebt,
  });

  final List<DebtRecord> debts;
  final VoidCallback onOpenDebts;
  final ValueChanged<DebtRecord> onOpenDebt;

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

class _StockFocusContent extends StatelessWidget {
  const _StockFocusContent({
    required this.products,
    required this.onOpenInventory,
  });

  final List<Product> products;
  final VoidCallback onOpenInventory;

  @override
  Widget build(BuildContext context) {
    return Column(
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
