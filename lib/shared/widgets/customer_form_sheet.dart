import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_models.dart';
import '../state/app_state.dart';

Future<Customer?> showCustomerFormSheet(
  BuildContext context,
  WidgetRef ref, {
  Customer? customer,
}) {
  return showModalBottomSheet<Customer>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _CustomerFormSheet(customer: customer, ref: ref),
  );
}

class _CustomerFormSheet extends StatefulWidget {
  const _CustomerFormSheet({required this.ref, this.customer});

  final WidgetRef ref;
  final Customer? customer;

  @override
  State<_CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends State<_CustomerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController = TextEditingController(
      text: widget.customer?.phone ?? '',
    );
    _addressController = TextEditingController(
      text: widget.customer?.address ?? '',
    );
    _notesController = TextEditingController(
      text: widget.customer?.notes ?? '',
    );
    _isActive = widget.customer?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.customer == null ? 'Pelanggan Baru' : 'Edit Pelanggan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama pelanggan',
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Nama wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'No. telepon'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'No. telepon wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Alamat'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Alamat wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Catatan'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _isActive,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pelanggan aktif'),
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _isActive = value),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _isSaving = true);
                    try {
                      final customer = await widget.ref
                          .read(posStateProvider)
                          .saveCustomer(
                            id: widget.customer?.id,
                            name: _nameController.text.trim(),
                            phone: _phoneController.text.trim(),
                            address: _addressController.text.trim(),
                            notes: _notesController.text.trim().isEmpty
                                ? null
                                : _notesController.text.trim(),
                              isActive: _isActive,
                          );
                      if (!context.mounted) return;
                      Navigator.of(context).pop(customer);
                    } finally {
                      if (mounted) {
                        setState(() => _isSaving = false);
                      }
                    }
                  },
                  child: Text(
                    widget.customer == null
                        ? (_isSaving ? 'Menyimpan...' : 'Simpan Pelanggan')
                        : (_isSaving ? 'Menyimpan...' : 'Update Pelanggan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
