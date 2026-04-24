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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(
          title: 'Stok & Inventory',
          subtitle:
              'Pantau stok menu jadi, bahan baku, dan pergerakan stok terbaru.',
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          children: [
            KpiCard(
              title: 'Produk Low Stock',
              value: '${state.lowStockProducts.length}',
              icon: Icons.warning_amber_rounded,
              color: AppTheme.warning,
            ),
            KpiCard(
              title: 'Pergerakan Hari Ini',
              value: '${state.stockMovements.length}',
              icon: Icons.swap_vert_circle_rounded,
              color: AppTheme.info,
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Produk Menipis'),
              const SizedBox(height: 12),
              ...state.lowStockProducts.map(
                (product) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(product.name),
                  subtitle: Text(
                    'Stok ${product.stockQty} ${product.unit} - Rak ${product.rackLocation ?? '-'}',
                  ),
                  trailing: StatusChip(
                    label: 'Min ${product.minStock}',
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
              const SectionHeader(title: 'Bahan Baku'),
              const SizedBox(height: 12),
              ...rawMaterials.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.$1),
                  subtitle: Text(item.$2),
                  trailing: Text(item.$3),
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
              const SectionHeader(title: 'Riwayat Pergerakan Stok'),
              const SizedBox(height: 12),
              ...state.stockMovements.take(8).map(
                    (movement) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor:
                            movement.type == StockMovementType.stockIn
                                ? AppTheme.success.withValues(alpha: 0.12)
                                : AppTheme.warning.withValues(alpha: 0.12),
                        child: Icon(
                          movement.type == StockMovementType.stockIn
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          color: movement.type == StockMovementType.stockIn
                              ? AppTheme.success
                              : AppTheme.warning,
                        ),
                      ),
                      title: Text(movement.referenceName),
                      subtitle: Text(
                        AppFormatters.dateTime(movement.createdAt),
                      ),
                      trailing: Text(
                        '${movement.type == StockMovementType.stockIn ? '+' : '-'}${movement.quantity.toStringAsFixed(0)}',
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
