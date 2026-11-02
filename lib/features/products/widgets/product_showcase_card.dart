import 'package:flutter/material.dart';

import '../../../shared/models/app_models.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/app_formatters.dart';
import '../../../shared/widgets/common_widgets.dart';

class ProductShowcaseCard extends StatelessWidget {
  const ProductShowcaseCard({
    super.key,
    required this.product,
    required this.categoryName,
    required this.imageHeight,
    required this.count,
    required this.forecastFuture,
    required this.onAdd,
    required this.onManage,
    required this.onLongPress,
    required this.showManageActions,
  });

  final Product product;
  final String categoryName;
  final double imageHeight;
  final int count;
  final Future<Map<String, double>> forecastFuture;
  final VoidCallback onAdd;
  final VoidCallback onManage;
  final VoidCallback? onLongPress;
  final bool showManageActions;

  @override
  Widget build(BuildContext context) {
    final isNasiPaket = categoryName.toLowerCase() == 'nasi paket';
    final canAdd = isNasiPaket ? product.isReady : product.stockQty > 0;
    final stockColor = !canAdd
        ? AppTheme.danger
        : !isNasiPaket && product.isLowStock
            ? AppTheme.warning
            : AppTheme.success;
    final stockLabel = isNasiPaket
        ? (product.isReady ? 'Siap dijual' : 'Sedang kosong')
        : product.stockQty == 0
            ? 'Stok habis'
            : 'Stok ${product.stockQty} ${product.unit}';
    final rack = product.rackLocation?.trim();

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onLongPress: onLongPress,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppTheme.deepTeal.withValues(alpha: 0.09),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.midnight.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    child: SizedBox(
                      height: imageHeight,
                      width: double.infinity,
                      child: AppMediaPreview(
                        imagePath: product.imagePath,
                        width: double.infinity,
                        height: double.infinity,
                        placeholderIcon: isNasiPaket
                            ? Icons.restaurant_rounded
                            : Icons.inventory_2_outlined,
                        label: null,
                        borderRadius: 0,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    right: showManageActions ? 52 : 10,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _CategoryBadge(label: categoryName),
                    ),
                  ),
                  if (showManageActions)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton.filled(
                        tooltip: 'Kelola produk',
                        onPressed: onManage,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.deepTeal,
                          fixedSize: const Size(36, 36),
                          minimumSize: const Size(36, 36),
                          padding: EdgeInsets.zero,
                        ),
                        icon: const Icon(Icons.more_horiz_rounded, size: 20),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 38,
                        child: Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppTheme.ink,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    height: 1.22,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 24,
                        width: double.infinity,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              AppFormatters.currency(product.sellPrice),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: AppTheme.deepTeal,
                                    fontSize: 17,
                                  ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ProductInfoLine(
                        icon: canAdd
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        text: stockLabel,
                        color: stockColor,
                      ),
                      const SizedBox(height: 4),
                      _ProductInfoLine(
                        icon: Icons.place_outlined,
                        text: rack == null || rack.isEmpty
                            ? 'Rak belum diatur'
                            : rack,
                        color: AppTheme.subtext,
                      ),
                      FutureBuilder<Map<String, double>>(
                        future: forecastFuture,
                        builder: (context, snapshot) {
                          final predictedQty = snapshot.data?[product.id];
                          if (predictedQty == null || predictedQty <= 0) {
                            return const SizedBox.shrink();
                          }
                          final stockDeficit =
                              !isNasiPaket && product.stockQty < predictedQty;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: _ProductInfoLine(
                              icon: stockDeficit
                                  ? Icons.warning_amber_rounded
                                  : Icons.show_chart_rounded,
                              text: stockDeficit
                                  ? 'Butuh ±${predictedQty.round()} besok'
                                  : 'Prediksi ±${predictedQty.round()} besok',
                              color: stockDeficit
                                  ? AppTheme.danger
                                  : AppTheme.teal,
                            ),
                          );
                        },
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: FilledButton(
                          onPressed: canAdd ? onAdd : null,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_shopping_cart_rounded,
                                  size: 17),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  canAdd
                                      ? count > 0
                                          ? 'Tambah ($count)'
                                          : 'Tambah'
                                      : 'Kosong',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final displayLabel = label.toLowerCase() == 'produk kemasan'
        ? 'Kemasan'
        : label.isEmpty
            ? label
            : '${label[0].toUpperCase()}${label.substring(1)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        displayLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppTheme.deepTeal,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProductInfoLine extends StatelessWidget {
  const _ProductInfoLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
          ),
        ),
      ],
    );
  }
}
