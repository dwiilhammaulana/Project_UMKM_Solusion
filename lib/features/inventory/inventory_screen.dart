import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/app_models.dart';
import '../../shared/state/app_state.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/app_formatters.dart';
import '../../shared/widgets/common_widgets.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posStateProvider);
    const rawMaterials = [
      ('Biji Kopi Arabica', '4.5 kg', 'Min 3 kg'),
      ('Susu UHT', '8 liter', 'Min 5 liter'),
      ('Gula Aren', '2.2 kg', 'Min 2 kg'),
      ('Minyak Goreng', '1.4 liter', 'Min 2 liter'),
    ];

    return AppPageScrollView(
      children: [
        HeroPanel(
          badge: const StatusChip(
            label: 'Inventory',
            color: Colors.white,
            icon: Icons.inventory_2_rounded,
          ),
          title: 'Pantau stok tanpa bikin layar terasa penuh.',
          subtitle:
              'Lihat item menipis, bahan baku, dan pergerakan stok terbaru dengan layout yang lebih mudah dibaca.',
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
              title: 'Produk Low Stock',
              value: '${state.lowStockProducts.length}',
              icon: Icons.warning_amber_rounded,
              color: AppTheme.warning,
            ),
            KpiCard(
              title: 'Pergerakan',
              value: '${state.stockMovements.length}',
              icon: Icons.swap_vert_circle_rounded,
              color: AppTheme.info,
            ),
          ],
        ),
        const SizedBox(height: 20),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Produk Menipis'),
              const SizedBox(height: 12),
              if (state.lowStockProducts.isEmpty)
                const EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Stok aman',
                  subtitle: 'Belum ada item yang menyentuh batas minimum.',
                )
              else
                ...state.lowStockProducts.map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          AppMediaPreview(
                            imagePath: product.imagePath,
                            width: 58,
                            height: 58,
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
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Stok ${product.stockQty} ${product.unit} · Rak ${product.rackLocation ?? '-'}',
                                ),
                              ],
                            ),
                          ),
                          StatusChip(
                            label: 'Min ${product.minStock}',
                            color: AppTheme.warning,
                          ),
                        ],
                      ),
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
              const SectionHeader(title: 'Bahan Baku'),
              const SizedBox(height: 12),
              ...rawMaterials.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppMenuLinkTile(
                    icon: Icons.local_drink_rounded,
                    title: item.$1,
                    subtitle: item.$2,
                    trailing: Text(
                      item.$3,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    onTap: () {},
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
              const SectionHeader(title: 'Riwayat Pergerakan Stok'),
              const SizedBox(height: 12),
              ...state.stockMovements.take(8).map(
                    (movement) => Padding(
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
                                color:
                                    movement.type == StockMovementType.stockIn
                                        ? AppTheme.success.withValues(alpha: 0.12)
                                        : AppTheme.warning.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                movement.type == StockMovementType.stockIn
                                    ? Icons.arrow_downward_rounded
                                    : Icons.arrow_upward_rounded,
                                color: movement.type == StockMovementType.stockIn
                                    ? AppTheme.success
                                    : AppTheme.warning,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    movement.referenceName,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(AppFormatters.dateTime(movement.createdAt)),
                                ],
                              ),
                            ),
                            Text(
                              '${movement.type == StockMovementType.stockIn ? '+' : '-'}${movement.quantity.toStringAsFixed(0)}',
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
