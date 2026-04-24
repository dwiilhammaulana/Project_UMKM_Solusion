import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/state/app_state.dart';
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
    final filtered = state.products.where((product) {
      final matchesQuery = product.name.toLowerCase().contains(
            _query.toLowerCase(),
          );
      final matchesCategory =
          _categoryId == null || product.categoryId == _categoryId;
      return matchesQuery && matchesCategory;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionHeader(
          title: 'Daftar Produk',
          subtitle:
              'Kelola menu kopi, makanan, dan stok awal untuk demo Android.',
          action: FilledButton.icon(
            key: const Key('products-add-button'),
            onPressed: () => showProductFormSheet(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Tambah'),
          ),
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          child: Column(
            children: [
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Cari produk...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Semua'),
                      selected: _categoryId == null,
                      onSelected: (_) => setState(() => _categoryId = null),
                    ),
                    const SizedBox(width: 8),
                    ...state.categories.map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category.name),
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
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Produk tidak ditemukan',
            subtitle: 'Coba ubah kata kunci atau filter kategori.',
          )
        else
          ...filtered.map((product) {
            final category = state.categories.firstWhere(
              (item) => item.id == product.categoryId,
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ProductCard(
                product: product,
                categoryName: category.name,
                count: state.cart[product.id] ?? 0,
                onAdd: () => ref.read(posStateProvider).addToCart(product),
                onEdit: () =>
                    showProductFormSheet(context, ref, product: product),
              ),
            );
          }),
      ],
    );
  }
}
