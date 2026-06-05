import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/models/app_models.dart';
import '../../shared/state/app_state.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/app_formatters.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/product_form_sheet.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _query = '';
  String? _categoryId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(posStateProvider);
    final query = _query.trim().toLowerCase();
    final filtered = state.products.where((product) {
      final matchesQuery =
          query.isEmpty || product.name.toLowerCase().contains(query);
      final matchesCategory =
          _categoryId == null || product.categoryId == _categoryId;
      return matchesQuery && matchesCategory;
    }).toList();

    return AppPageScrollView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
      children: [
        AppCleanTopHero(
          title: 'Produk',
          subtitle:
              'Setiap item memiliki slot thumbnail utama agar katalog dan kasir terasa lebih menarik.',
          accentIcon: Icons.inventory_2_rounded,
          accentLabel: 'Katalog',
          heightFactor: 0.38,
          minHeight: 300,
          maxHeight: 390,
          bottom: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              const StatusChip(
                label: 'Katalog produk',
                color: Colors.white,
                icon: Icons.photo_library_outlined,
              ),
              StatusChip(
                label: '${state.products.length} produk',
                color: Colors.white,
                icon: Icons.inventory_2_rounded,
              ),
              StatusChip(
                label: '${state.lowStockProducts.length} stok tipis',
                color: Colors.white,
                icon: Icons.warning_amber_rounded,
              ),
              if (state.cartCount > 0) ...[
                StatusChip(
                  label: '${state.cartCount} item dipilih',
                  color: Colors.white,
                  icon: Icons.shopping_cart_rounded,
                ),
                FilledButton.icon(
                  key: const Key('products-open-cashier-button'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.deepTeal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: () => context.go('/cashier'),
                  icon: const AppIcon(Icons.point_of_sale_rounded),
                  label: const Text('Ke Kasir'),
                ),
              ],
              FilledButton.icon(
                key: const Key('products-add-button'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.deepTeal,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () => showProductFormSheet(context, ref),
                icon: const AppIcon(Icons.add_rounded),
                label: const Text('Tambah Produk'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Etalase Produk',
                  subtitle:
                      '${filtered.length} item tampil dari ${state.products.length} produk.',
                ),
                const SizedBox(height: 14),
                AppSearchField(
                  hintText: 'Cari produk...',
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      AppFilterChip(
                        label: 'Semua',
                        selected: _categoryId == null,
                        onSelected: (_) => setState(() => _categoryId = null),
                      ),
                      const SizedBox(width: 8),
                      ...state.categories.map(
                        (category) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AppFilterChip(
                            label: category.name,
                            selected: _categoryId == category.id,
                            onSelected: (_) =>
                                setState(() => _categoryId = category.id),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Produk tidak ditemukan',
              subtitle: 'Coba ubah kata kunci atau filter kategori.',
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width >= 820
                    ? 4
                    : width >= 560
                        ? 3
                        : 2;
                const gridGap = 12.0;
                final cardWidth =
                    (width - (crossAxisCount - 1) * gridGap) / crossAxisCount;
                final cardHeight = cardWidth + 224;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: gridGap,
                    mainAxisSpacing: gridGap,
                    mainAxisExtent: cardHeight,
                  ),
                  itemBuilder: (context, index) {
                    final product = filtered[index];

                    return _ProductShowcaseCard(
                      key: Key('product-card-${product.id}'),
                      product: product,
                      categoryName: state.categoryNameById(product.categoryId),
                      count: state.cart[product.id] ?? 0,
                      onAdd: () {
                        try {
                          ref.read(posStateProvider).addToCart(product);
                        } catch (error) {
                          _showMessage(
                            error.toString().replaceFirst('Exception: ', ''),
                          );
                        }
                      },
                      onEdit: () =>
                          showProductFormSheet(context, ref, product: product),
                      onLongPress: () => _showProductActions(context, product),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _showProductActions(
    BuildContext context,
    Product product,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BottomSheetContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Tahan lama produk untuk membuka aksi cepat seperti edit atau hapus.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  showProductFormSheet(this.context, ref, product: product);
                },
                icon: const AppIcon(Icons.edit_outlined),
                label: const Text('Edit Produk'),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                key: Key('product-delete-button-${product.id}'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _confirmDeleteProduct(product);
                },
                icon: const AppIcon(Icons.delete_outline_rounded),
                label: const Text('Hapus Produk'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteProduct(Product product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus produk?'),
          content: Text(
            'Produk ${product.name} akan dihapus dari katalog. Data ini tidak bisa dikembalikan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              key: Key('product-confirm-delete-${product.id}'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.danger,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    try {
      await ref.read(posStateProvider).deleteProduct(product.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} berhasil dihapus.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProductShowcaseCard extends StatelessWidget {
  const _ProductShowcaseCard({
    super.key,
    required this.product,
    required this.categoryName,
    required this.count,
    required this.onAdd,
    required this.onEdit,
    required this.onLongPress,
  });

  final Product product;
  final String categoryName;
  final int count;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final stockColor = product.isLowStock ? AppTheme.warning : AppTheme.success;
    final stockLabel = product.isLowStock ? 'Stok tipis' : 'Tersedia';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onLongPress: onLongPress,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.deepTeal.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.midnight.withValues(alpha: 0.07),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: AppMediaPreview(
                        imagePath: product.imagePath,
                        width: double.infinity,
                        height: double.infinity,
                        label: 'Foto\nproduk',
                        borderRadius: 0,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Row(
                      children: [
                        Expanded(
                          child: _ShowcaseBadge(
                            label: categoryName,
                            color: AppTheme.deepTeal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ShowcaseIconButton(
                          tooltip: 'Edit produk',
                          icon: Icons.edit_outlined,
                          onPressed: onEdit,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppFormatters.currency(product.sellPrice),
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppTheme.deepTeal,
                                  ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: _ShowcaseBadge(
                              label:
                                  '$stockLabel ${product.stockQty} ${product.unit}',
                              color: stockColor,
                            ),
                          ),
                        ],
                      ),
                      if ((product.rackLocation ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _ShowcaseBadge(
                          label: product.rackLocation!,
                          color: AppTheme.info,
                        ),
                      ],
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(42),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: onAdd,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AppIcon(
                                Icons.add_shopping_cart_rounded,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  count > 0 ? 'Tambah ($count)' : 'Tambah',
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

class _ShowcaseBadge extends StatelessWidget {
  const _ShowcaseBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
      ),
    );
  }
}

class _ShowcaseIconButton extends StatelessWidget {
  const _ShowcaseIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 34,
        height: 34,
        child: IconButton.filled(
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.92),
            foregroundColor: AppTheme.deepTeal,
          ),
          onPressed: onPressed,
          icon: AppIcon(icon, size: 18),
        ),
      ),
    );
  }
}
