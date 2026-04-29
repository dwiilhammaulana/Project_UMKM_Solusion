import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/auth/auth_controller.dart';
import '../../shared/state/app_state.dart';
import '../../shared/utils/media_picker.dart';
import '../../shared/widgets/common_widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _storeSubtitleController = TextEditingController(
    text: 'Pantau penjualan, stok, dan bon dalam satu aplikasi.',
  );
  final _ownerNameController = TextEditingController();
  String? _photoPath;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authControllerProvider);
    _ownerNameController.text = auth.displayName ?? '';
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(
          colors: [Color(0xFFF4FBFA), Color(0xFFEAF4F3), Color(0xFFFDFEFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: AppSectionCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lengkapi profil toko',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Satu akun mewakili satu toko. Isi identitas toko dulu supaya dashboard dan data penjualan siap dipakai.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
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
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          _isSubmitting ? null : _pickPhoto,
                                      icon:
                                          const Icon(Icons.add_a_photo_outlined),
                                      label: Text(
                                        _photoPath == null
                                            ? 'Upload Foto'
                                            : 'Ganti Foto',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          _isSubmitting || _photoPath == null
                                              ? null
                                              : () => setState(
                                                    () => _photoPath = null,
                                                  ),
                                      icon:
                                          const Icon(Icons.delete_outline_rounded),
                                      label: const Text('Kosongkan'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _storeNameController,
                          decoration:
                              const InputDecoration(labelText: 'Nama toko'),
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? 'Nama toko wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _ownerNameController,
                          decoration:
                              const InputDecoration(labelText: 'Nama pemilik'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _storeSubtitleController,
                          maxLines: 2,
                          decoration:
                              const InputDecoration(labelText: 'Subtitle toko'),
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? 'Subtitle toko wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSubmitting ? null : _submit,
                            child: Text(
                              _isSubmitting
                                  ? 'Menyimpan...'
                                  : 'Simpan dan masuk dashboard',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final picked = await ref.read(mediaPickerProvider).pickImagePath();
    if (!mounted || picked == null) {
      return;
    }
    setState(() => _photoPath = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref.read(posStateProvider).saveAppProfile(
            storeName: _storeNameController.text.trim(),
            storeSubtitle: _storeSubtitleController.text.trim(),
            ownerName: _ownerNameController.text.trim().isEmpty
                ? null
                : _ownerNameController.text.trim(),
            photoPath: _photoPath,
          );
      await ref.read(authControllerProvider).refreshProfileStatus();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
