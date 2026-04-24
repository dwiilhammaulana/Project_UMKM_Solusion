import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_models.dart';
import '../state/app_state.dart';

Future<void> showProductFormSheet(
  BuildContext context,
  WidgetRef ref, {
  Product? product,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ProductFormSheet(product: product, ref: ref),
  );
}

class _ProductFormSheet extends StatefulWidget {
  const _ProductFormSheet({required this.ref, this.product});

  final WidgetRef ref;
  final Product? product;

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _sellPriceController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _minStockController;
  late final TextEditingController _unitController;
  late final TextEditingController _rackController;
  late String _categoryId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final categories = widget.ref.read(posStateProvider).categories;
    _categoryId = widget.product?.categoryId ?? categories.first.id;
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _sellPriceController = TextEditingController(
      text: widget.product?.sellPrice.toStringAsFixed(0) ?? '',
    );
    _costPriceController = TextEditingController(
      text: widget.product?.costPrice.toStringAsFixed(0) ?? '',
    );
    _stockController = TextEditingController(
      text: widget.product?.stockQty.toString() ?? '',
    );
    _minStockController = TextEditingController(
      text: widget.product?.minStock.toString() ?? '',
    );
    _unitController = TextEditingController(text: widget.product?.unit ?? '');
    _rackController = TextEditingController(
      text: widget.product?.rackLocation ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sellPriceController.dispose();
    _costPriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _unitController.dispose();
    _rackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.ref.watch(posStateProvider).categories;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Material(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.product == null ? 'Produk Baru' : 'Edit Produk',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nama produk'),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Nama wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    items: categories
                        .map<DropdownMenuItem<String>>(
                          (category) => DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        )
                        .toList(),
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _categoryId = value!),
                    decoration: const InputDecoration(labelText: 'Kategori'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _sellPriceController,
                    decoration: const InputDecoration(labelText: 'Harga jual'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _costPriceController,
                    decoration: const InputDecoration(labelText: 'Harga modal'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _stockController,
                          decoration: const InputDecoration(labelText: 'Stok'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _minStockController,
                          decoration: const InputDecoration(
                            labelText: 'Min stok',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _unitController,
                          decoration: const InputDecoration(
                            labelText: 'Satuan',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _rackController,
                          decoration: const InputDecoration(
                            labelText: 'Lokasi rak',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isSaving
                        ? null
                        : () async {
                      if (!_formKey.currentState!.validate()) return;
                      setState(() => _isSaving = true);
                      try {
                        await widget.ref.read(posStateProvider).saveProduct(
                            id: widget.product?.id,
                            name: _nameController.text.trim(),
                            categoryId: _categoryId,
                            sellPrice:
                                double.tryParse(_sellPriceController.text) ?? 0,
                            costPrice:
                                double.tryParse(_costPriceController.text) ?? 0,
                            stockQty: int.tryParse(_stockController.text) ?? 0,
                            minStock:
                                int.tryParse(_minStockController.text) ?? 0,
                            unit: _unitController.text.trim().isEmpty
                                ? 'pcs'
                                : _unitController.text.trim(),
                            rackLocation: _rackController.text.trim(),
                          );
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                      } finally {
                        if (mounted) {
                          setState(() => _isSaving = false);
                        }
                      }
                    },
                    child: Text(
                      widget.product == null
                          ? (_isSaving ? 'Menyimpan...' : 'Simpan Produk')
                          : (_isSaving ? 'Menyimpan...' : 'Update Produk'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
