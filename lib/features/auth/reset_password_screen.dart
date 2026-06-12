import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/auth/auth_controller.dart';
import '../../shared/auth/auth_repository.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/common_widgets.dart';
import 'auth_scaffold.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  static final ButtonStyle _primaryButtonStyle = FilledButton.styleFrom(
    backgroundColor: Colors.white.withValues(alpha: 0.72),
    foregroundColor: AppTheme.deepTeal,
    padding: const EdgeInsets.symmetric(vertical: 16),
  );

  static final ButtonStyle _textButtonStyle = TextButton.styleFrom(
    foregroundColor: AppTheme.deepTeal,
  );

  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final canResetPassword =
        auth.status == AuthStatus.passwordRecovery && auth.isAuthenticated;

    return AuthScaffold(
      title: 'Ubah password',
      subtitle: canResetPassword
          ? 'Buat password baru untuk masuk kembali ke Toko Saku.'
          : 'Link ubah password tidak valid atau sudah kedaluwarsa.',
      backgroundColor: AppTheme.deepTeal,
      backgroundImage: 'bg login.png',
      frameless: true,
      showBrand: false,
      contentAlignment: const Alignment(0, 0.58),
      paintBackground: false,
      child: canResetPassword ? _buildResetForm() : _buildInvalidLink(),
    );
  }

  Widget _buildResetForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            style: const TextStyle(color: AppTheme.deepTeal),
            decoration: _inputDecoration(
              labelText: 'Password baru',
              prefixIcon: Icons.lock_outline_rounded,
            ),
            validator: (value) {
              final text = value ?? '';
              if (text.isEmpty) {
                return 'Password baru wajib diisi';
              }
              if (text.length < 8) {
                return 'Password minimal 8 karakter';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            style: const TextStyle(color: AppTheme.deepTeal),
            decoration: _inputDecoration(
              labelText: 'Konfirmasi password',
              prefixIcon: Icons.lock_reset_rounded,
            ),
            validator: (value) {
              final text = value ?? '';
              if (text.isEmpty) {
                return 'Konfirmasi password wajib diisi';
              }
              if (text != _passwordController.text) {
                return 'Konfirmasi password belum sama';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submitNewPassword,
              style: _primaryButtonStyle,
              child: Text(_isSubmitting ? 'Menyimpan...' : 'Ubah Password'),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _isSubmitting ? null : () => context.go('/login'),
              style: _textButtonStyle,
              child: const Text('Kembali ke login'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvalidLink() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(
                Icons.info_outline_rounded,
                color: AppTheme.deepTeal,
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Minta link baru dari halaman login, lalu buka email terbaru yang dikirim Supabase.',
                  style: TextStyle(color: AppTheme.deepTeal),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () => context.go('/login'),
          style: _primaryButtonStyle,
          child: const Text('Kembali ke Login'),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: AppTheme.deepTeal.withValues(alpha: 0.72)),
      prefixIcon: AppIcon(
        prefixIcon,
        color: AppTheme.deepTeal,
        size: 16,
      ),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 40,
        minHeight: 40,
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.58),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.72),
          width: 1.4,
        ),
      ),
    );
  }

  Future<void> _submitNewPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(authControllerProvider)
          .updatePassword(_passwordController.text);

      if (!mounted) return;
      _showMessage('Password berhasil diubah. Silakan login kembali.');
      context.go('/login');
    } on AuthFailure catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
