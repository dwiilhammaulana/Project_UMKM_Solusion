import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_models.dart';
import '../state/app_state.dart';
import '../utils/media_picker.dart';
import 'common_widgets.dart';

Future<void> showStoreProfileSheet(
  BuildContext context,
  WidgetRef ref, {
  required AppProfile profile,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _StoreProfileSheet(profile: profile, ref: ref),
  );
}

class _StoreProfileSheet extends StatefulWidget {
  const _StoreProfileSheet({required this.profile, required this.ref});

  final AppProfile profile;
  final WidgetRef ref;

  @override
  State<_StoreProfileSheet> createState() => _StoreProfileSheetState();
}

class _StoreProfileSheetState extends State<_StoreProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _storeNameController;
  late final TextEditingController _storeSubtitleController;
  late final TextEditingController _ownerNameController;
  late String? _photoPath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _storeNameController = TextEditingController(
      text: widget.profile.storeName,
    );
    _storeSubtitleController = TextEditingController(
      text: widget.profile.storeSubtitle,
    );
    _ownerNameController = TextEditingController(
      text: widget.profile.ownerName ?? '',
    );
    _photoPath = widget.profile.photoPath;
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeSubtitleController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetContainer(
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Profil Toko',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Kelola nama toko, pemilik, dan foto profil utama aplikasi.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppMediaPreview(
                    imagePath: _photoPath,
                    width: 112,
                    height: 112,
                    borderRadius: 56,
                    placeholderIcon: Icons.storefront_rounded,
                    label: 'Foto\nprofil',
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      children: [
                        OutlinedButton.icon(
                          key: const Key('store-image-pick-button'),
                          onPressed: _isSaving ? null : _pickPhoto,
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: Text(
                            _photoPath == null ? 'Upload Foto' : 'Ganti Foto',
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          key: const Key('store-image-clear-button'),
                          onPressed: _isSaving || _photoPath == null
                              ? null
                              : () => setState(() => _photoPath = null),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Kosongkan'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _storeNameController,
                decoration: const InputDecoration(labelText: 'Nama toko'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Nama toko wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ownerNameController,
                decoration: const InputDecoration(labelText: 'Nama pemilik'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _storeSubtitleController,
                decoration: const InputDecoration(labelText: 'Subtitle toko'),
                maxLines: 2,
                validator: (value) => value == null || value.isEmpty
                    ? 'Subtitle toko wajib diisi'
                    : null,
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: Text(_isSaving ? 'Menyimpan...' : 'Simpan Profil'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final picked = await widget.ref.read(mediaPickerProvider).pickImagePath();
    if (!mounted || picked == null) {
      return;
    }
    setState(() => _photoPath = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await widget.ref.read(posStateProvider).saveAppProfile(
            storeName: _storeNameController.text.trim(),
            ownerName: _ownerNameController.text.trim().isEmpty
                ? null
                : _ownerNameController.text.trim(),
            storeSubtitle: _storeSubtitleController.text.trim(),
            photoPath: _photoPath,
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
