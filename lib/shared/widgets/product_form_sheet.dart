import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/media_picker.dart';
import 'common_widgets.dart';

const _productCategoryNames = [
  'nasi paket',
  'sembako',
  'produk kemasan',
];

const _rackLocationOptions = [
  'meja kasir',
  'etalase nasi',
  'gantungan depan',
  'gantungan samping',
  'rak ambalan depan',
];

const _unitOptions = [
  'Pcs',
  'Renceng',
  'Dus',
  'Pack',
  'Porsi',
];

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
  late String _categoryId;
  late String _unit;
  late String _rackLocation;
  String? _imagePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final categories = widget.ref.read(posStateProvider).categories;
    final categoryOptions = _productCategoryOptions(categories);
    _categoryId = _initialCategoryId(categoryOptions);
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
    _unit = _unitOptions.contains(widget.product?.unit)
        ? widget.product!.unit
        : _unitOptions.first;
    _rackLocation = _rackLocationOptions.contains(widget.product?.rackLocation)
        ? widget.product!.rackLocation!
        : _rackLocationOptions.first;
    _imagePath = widget.product?.imagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sellPriceController.dispose();
    _costPriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.ref.watch(posStateProvider).categories;
    final categoryOptions = _productCategoryOptions(categories);
    final categoryIds = categoryOptions.map((category) => category.id).toSet();
    final effectiveCategoryId = categoryIds.contains(_categoryId)
        ? _categoryId
        : categoryOptions.first.id;
    if (effectiveCategoryId != _categoryId) {
      _categoryId = effectiveCategoryId;
    }

    return BottomSheetContainer(
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.product == null ? 'Produk Baru' : 'Edit Produk',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Siapkan detail menu, stok, dan foto utama produk.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppMediaPreview(
                    imagePath: _imagePath,
                    width: 112,
                    height: 112,
                    label: 'Foto\nproduk',
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      children: [
                        OutlinedButton(
                          key: const Key('product-image-pick-button'),
                          onPressed: _isSaving ? null : _pickImage,
                          child: Text(
                            _imagePath == null ? 'Upload Foto' : 'Ganti Foto',
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          key: const Key('product-image-clear-button'),
                          onPressed: _isSaving || _imagePath == null
                              ? null
                              : () => setState(() => _imagePath = null),
                          child: const Text('Hapus Foto'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama produk'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              _ProductDropdownField(
                value: effectiveCategoryId,
                labelText: 'Kategori',
                items: categoryOptions
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
                      decoration: const InputDecoration(labelText: 'Min stok'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ProductDropdownField(
                      value: _unit,
                      labelText: 'Satuan',
                      items: _unitOptions
                          .map<DropdownMenuItem<String>>(
                            (unit) => DropdownMenuItem<String>(
                              value: unit,
                              child: Text(unit),
                            ),
                          )
                          .toList(),
                      onChanged: _isSaving
                          ? null
                          : (value) => setState(() => _unit = value!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ProductDropdownField(
                      value: _rackLocation,
                      labelText: 'Lokasi rak',
                      items: _rackLocationOptions
                          .map<DropdownMenuItem<String>>(
                            (rackLocation) => DropdownMenuItem<String>(
                              value: rackLocation,
                              child: Text(rackLocation),
                            ),
                          )
                          .toList(),
                      onChanged: _isSaving
                          ? null
                          : (value) => setState(() => _rackLocation = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _isSaving ? null : _save,
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
    );
  }

  List<Category> _productCategoryOptions(List<Category> categories) {
    final filtered = categories
        .where((category) => _productCategoryNames.contains(category.name))
        .toList()
      ..sort((a, b) {
        return _productCategoryNames
            .indexOf(a.name)
            .compareTo(_productCategoryNames.indexOf(b.name));
      });
    return filtered.isEmpty ? categories : filtered;
  }

  String _initialCategoryId(List<Category> categories) {
    final productCategoryId = widget.product?.categoryId;
    if (productCategoryId != null &&
        categories.any((category) => category.id == productCategoryId)) {
      return productCategoryId;
    }
    return categories.first.id;
  }

  Future<void> _pickImage() async {
    try {
      final picked = await widget.ref.read(mediaPickerProvider).pickImagePath();
      if (!mounted || picked == null) {
        return;
      }
      setState(() => _imagePath = picked);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal upload foto: $error')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await widget.ref.read(posStateProvider).saveProduct(
            id: widget.product?.id,
            name: _nameController.text.trim(),
            categoryId: _categoryId,
            sellPrice: double.tryParse(_sellPriceController.text) ?? 0,
            costPrice: double.tryParse(_costPriceController.text) ?? 0,
            stockQty: int.tryParse(_stockController.text) ?? 0,
            minStock: int.tryParse(_minStockController.text) ?? 0,
            unit: _unit,
            rackLocation: _rackLocation,
            imagePath: _imagePath,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _ProductDropdownField extends StatelessWidget {
  const _ProductDropdownField({
    required this.value,
    required this.labelText,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final String labelText;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(20),
      icon: const AppIcon(
        Icons.keyboard_arrow_down_rounded,
        color: AppTheme.deepTeal,
        size: 16,
      ),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.ink,
            fontWeight: FontWeight.w800,
          ),
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: AppTheme.deepTeal.withValues(alpha: 0.20),
            width: 1.2,
          ),
        ),
      ),
    );
  }
}
