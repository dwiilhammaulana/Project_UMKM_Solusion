import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/auth/auth_controller.dart';
import '../../shared/models/app_models.dart';
import '../../shared/state/app_state.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/product_form_sheet.dart';
import 'widgets/product_showcase_card.dart';

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
  final PredictionService _predictionService = PredictionService();
  String _query = '';
  String? _categoryId;
  String? _forecastCacheKey;
  Future<Map<String, double>>? _forecastFuture;

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
    final forecastDate = _forecastDateForTomorrow();
    final forecastFuture = _forecastFutureFor(state.products, forecastDate);

    return CustomScrollView(
      scrollCacheExtent: const ScrollCacheExtent.pixels(360),
      slivers: [
        SliverToBoxAdapter(
          child: _ProductsCompactHeader(
            productCount: state.products.length,
            cartCount: state.cartCount,
            categories: productCategories,
            selectedCategoryId: _categoryId,
            onSearchChanged: (value) => setState(() => _query = value),
            onCategorySelected: (categoryId) => setState(
              () => _categoryId = _categoryId == categoryId ? null : categoryId,
            ),
            onAddProduct: canManageProducts
                ? () => showProductFormSheet(context, ref)
                : null,
            onOpenCashier: () => context.go('/cashier'),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Etalase Produk',
              action: Text(
                '${filtered.length} item',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.deepTeal,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        if (filtered.isEmpty)
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Produk tidak ditemukan',
                subtitle: 'Coba ubah kata kunci atau filter kategori.',
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                final crossAxisCount = width >= 950
                    ? 5
                    : width >= 740
                        ? 4
                        : width >= 500
                            ? 3
                            : width >= 300
                                ? 2
                                : 1;
                const gridColumnGap = 12.0;
                const gridRowGap = 14.0;
                final cardWidth =
                    (width - (crossAxisCount - 1) * gridColumnGap) /
                        crossAxisCount;
                final imageHeight = crossAxisCount == 1
                    ? 160.0
                    : (cardWidth * 0.78).clamp(110.0, 160.0);
                final cardHeight = imageHeight + 200;

                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: gridColumnGap,
                    mainAxisSpacing: gridRowGap,
                    mainAxisExtent: cardHeight,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = filtered[index];
                      return ProductShowcaseCard(
                        key: Key('product-card-${product.id}'),
                        product: product,
                        categoryName:
                            state.categoryNameById(product.categoryId),
                        imageHeight: imageHeight,
                        count: state.cart[product.id] ?? 0,
                        forecastFuture: forecastFuture,
                        onAdd: () {
                          try {
                            ref.read(posStateProvider).addToCart(product);
                          } catch (error) {
                            _showMessage(
                              error.toString().replaceFirst('Exception: ', ''),
                            );
                          }
                        },
                        onManage: () => _showProductActions(context, product),
                        onLongPress: canManageProducts
                            ? () => _showProductActions(context, product)
                            : null,
                        showManageActions: canManageProducts,
                      );
                    },
                    childCount: filtered.length,
                  ),
                );
              },
            ),
          ),
        SliverToBoxAdapter(
          child: SizedBox(height: shellBottomClearance(context) + 20),
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
                'Pilih tindakan untuk produk ini.',
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

  Future<Map<String, double>> _forecastFutureFor(
    List<Product> products,
    String targetDate,
  ) {
    final productIds = products.map((product) => product.id).toList()..sort();
    final cacheKey = '$targetDate|${productIds.join(',')}';
    if (_forecastCacheKey != cacheKey || _forecastFuture == null) {
      _forecastCacheKey = cacheKey;
      _forecastFuture = _predictionService.getSalesForecasts(
        productIds: productIds,
        targetDate: targetDate,
        isPromoActive: false,
      );
    }
    return _forecastFuture!;
  }

  String _forecastDateForTomorrow() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return DateUtils.dateOnly(tomorrow).toIso8601String().split('T').first;
  }

  Future<void> _confirmDeleteProduct(Product product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus produk?'),
          content: Text(
            'Produk ${product.name} akan dihapus dari katalog. Riwayat transaksi dan BON tetap tersimpan.',
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
    required this.productCount,
    required this.cartCount,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSearchChanged,
    required this.onCategorySelected,
    required this.onAddProduct,
    required this.onOpenCashier,
  });

  final int productCount;
  final int cartCount;
  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCategorySelected;
  final VoidCallback? onAddProduct;
  final VoidCallback onOpenCashier;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        topInset + 14,
        20,
        18,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.midnight, AppTheme.deepTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Produk',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                              ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cartCount > 0
                          ? '$productCount produk · $cartCount di keranjang'
                          : '$productCount produk',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (onAddProduct != null)
                _CompactAddProductButton(onPressed: onAddProduct!)
              else
                OutlinedButton.icon(
                  onPressed: onOpenCashier,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.shopping_cart_outlined, size: 17),
                  label:
                      Text(cartCount > 0 ? 'Kasir ($cartCount)' : 'Ke Kasir'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          AppSearchField(
            hintText: 'Cari nama produk',
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CompactCategoryChip(
                  label: 'Semua',
                  selected: selectedCategoryId == null,
                  onTap: () => onCategorySelected(null),
                ),
                for (final category in categories) ...[
                  const SizedBox(width: 8),
                  _CompactCategoryChip(
                    label: category.name,
                    selected: selectedCategoryId == category.id,
                    onTap: () => onCategorySelected(category.id),
                  ),
                ],
              ],
            ),
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
    return FilledButton.icon(
      key: const Key('products-add-button'),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.deepTeal,
        minimumSize: const Size(0, 42),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Tambah Produk'),
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
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                selected ? Colors.white : Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: selected ? 1 : 0.32),
            ),
          ),
          child: Text(
            label.isEmpty
                ? label
                : '${label[0].toUpperCase()}${label.substring(1)}',
            maxLines: 1,
            style: TextStyle(
              color: selected ? AppTheme.deepTeal : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

// SERVICE PREDICTION MENGGUNAKAN SUPABASE
class PredictionService {
  Future<Map<String, double>> getSalesForecasts({
    required List<String> productIds,
    required String targetDate,
    required bool isPromoActive,
  }) async {
    if (productIds.isEmpty) {
      return const {};
    }

    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('product_forecasts')
          .select('product_id, predicted_quantity')
          .inFilter('product_id', productIds)
          .eq('target_date', targetDate);

      return {
        for (final row in response)
          if (row['product_id'] != null && row['predicted_quantity'] != null)
            row['product_id'] as String: _promoAdjustedQuantity(
                row['predicted_quantity'], isPromoActive),
      };
    } catch (error, stackTrace) {
      developer.log(
        'Gagal mengambil data prediksi dari Supabase',
        name: 'PredictionService',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return const {};
  }

  double _promoAdjustedQuantity(Object value, bool isPromoActive) {
    final predictedQty = value as num;
    if (isPromoActive) {
      return predictedQty.toDouble() * 1.30;
    }
    return predictedQty.toDouble();
  }
}
