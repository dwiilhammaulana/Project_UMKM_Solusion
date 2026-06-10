import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/auth/auth_controller.dart';
import '../../shared/models/app_models.dart';
import '../../shared/state/app_state.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/app_formatters.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/product_form_sheet.dart';

const _productCategoryNames = [
  'nasi paket',
  'sembako',
  'produk kemasan',
];

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
    final auth = ref.watch(authControllerProvider);
    final canManageProducts = auth.isAdmin;
    final query = _query.trim().toLowerCase();
    final filtered = state.products.where((product) {
      final matchesQuery =
          query.isEmpty || product.name.toLowerCase().contains(query);
      final matchesCategory =
          _categoryId == null || product.categoryId == _categoryId;
      return matchesQuery && matchesCategory;
    }).toList();
    final productCategories = state.categories
        .where((category) => _productCategoryNames.contains(category.name))
        .take(3)
        .toList();

    return AppPageScrollView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
      children: [
        _ProductsCompactHeader(
          categories: productCategories,
          selectedCategoryId: _categoryId,
          onSearchChanged: (value) => setState(() => _query = value),
          onCategorySelected: (categoryId) => setState(
            () => _categoryId = _categoryId == categoryId ? null : categoryId,
          ),
          onAddProduct: canManageProducts
              ? () => showProductFormSheet(context, ref)
              : null,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Etalase Produk',
                action: StatusChip(
                  label: '${state.products.length} produk aktif',
                  color: AppTheme.deepTeal,
                ),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Produk tidak ditemukan',
                  subtitle: 'Coba ubah kata kunci atau filter kategori.',
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width >= 820
                        ? 4
                        : width >= 560
                            ? 3
                            : 2;
                    const gridGap = 12.0;
                    final cardWidth = (width - (crossAxisCount - 1) * gridGap) /
                        crossAxisCount;
                    return Wrap(
                      spacing: gridGap,
                      runSpacing: gridGap,
                      children: [
                        for (final product in filtered)
                          SizedBox(
                            width: cardWidth,
                            child: _ProductShowcaseCard(
                              key: Key('product-card-${product.id}'),
                              product: product,
                              categoryName:
                                  state.categoryNameById(product.categoryId),
                              count: state.cart[product.id] ?? 0,
                              onAdd: () {
                                try {
                                  ref.read(posStateProvider).addToCart(product);
                                } catch (error) {
                                  _showMessage(
                                    error
                                        .toString()
                                        .replaceFirst('Exception: ', ''),
                                  );
                                }
                              },
                              onEdit: () => showProductFormSheet(
                                context,
                                ref,
                                product: product,
                              ),
                              onLongPress: canManageProducts
                                  ? () => _showProductActions(context, product)
                                  : null,
                              showManageActions: canManageProducts,
                            ),
                          ),
                      ],
                    );
                  },
                ),
            ],
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

class _ProductsCompactHeader extends StatelessWidget {
  const _ProductsCompactHeader({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSearchChanged,
    required this.onCategorySelected,
    required this.onAddProduct,
  });

  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback? onAddProduct;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topInset + 12, 20, 14),
      decoration: BoxDecoration(
        color: AppTheme.deepTeal,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.midnight.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppSearchField(
                  hintText: 'Cari produk...',
                  onChanged: onSearchChanged,
                ),
              ),
              if (onAddProduct != null) ...[
                const SizedBox(width: 10),
                _CompactAddProductButton(onPressed: onAddProduct!),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final category in categories) ...[
                Expanded(
                  child: _CompactCategoryChip(
                    label: category.name,
                    selected: selectedCategoryId == category.id,
                    onTap: () => onCategorySelected(category.id),
                  ),
                ),
                if (category != categories.last) const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactAddProductButton extends StatelessWidget {
  const _CompactAddProductButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: 52,
      child: FilledButton(
        key: const Key('products-add-button'),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.deepTeal,
          padding: EdgeInsets.zero,
          minimumSize: const Size(52, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onPressed,
        child: const Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 0,
              child: Text(
                'Tambah Produk',
                style: TextStyle(fontSize: 0),
              ),
            ),
            AppIcon(Icons.inventory_2_rounded, size: 20),
            Positioned(
              right: -7,
              bottom: -5,
              child: AppIcon(Icons.add_rounded, size: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactCategoryChip extends StatelessWidget {
  const _CompactCategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                selected ? Colors.white : Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: selected ? 0.94 : 0.28),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: selected ? AppTheme.deepTeal : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
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
    required this.showManageActions,
  });

  final Product product;
  final String categoryName;
  final int count;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback? onLongPress;
  final bool showManageActions;

  @override
  Widget build(BuildContext context) {
    final isNasiPaket = categoryName.toLowerCase() == 'nasi paket';
    final stockColor = isNasiPaket
        ? (product.isReady ? AppTheme.success : AppTheme.danger)
        : (product.isLowStock ? AppTheme.warning : AppTheme.success);
    final stockLabel = isNasiPaket
        ? (product.isReady ? 'Ready' : 'Kosong')
        : (product.isLowStock ? 'Stok tipis' : 'Tersedia');

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
                        if (showManageActions) ...[
                          const SizedBox(width: 8),
                          _ShowcaseIconButton(
                            tooltip: 'Edit produk',
                            icon: Icons.edit_outlined,
                            onPressed: onEdit,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppFormatters.currency(product.sellPrice),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.deepTeal,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _ShowcaseBadge(
                            label: isNasiPaket
                                ? stockLabel
                                : '$stockLabel ${product.stockQty} ${product.unit}',
                            color: stockColor,
                            compact: true,
                          ),
                        ),
                        if ((product.rackLocation ?? '').trim().isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: _ShowcaseBadge(
                              label: product.rackLocation!,
                              color: AppTheme.info,
                              compact: true,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(36),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed:
                            isNasiPaket && !product.isReady ? null : onAdd,
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
                                isNasiPaket && !product.isReady
                                    ? 'Kosong'
                                    : (count > 0
                                        ? 'Tambah ($count)'
                                        : 'Tambah'),
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
    this.compact = false,
  });

  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 8,
        vertical: compact ? 4 : 6,
      ),
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
              fontSize: compact ? 9 : 10,
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
