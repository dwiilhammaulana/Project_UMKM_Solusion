import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/auth/auth_controller.dart';
import '../../shared/auth/auth_repository.dart';
import '../../shared/biometrics/biometric_lock_controller.dart';
import '../../shared/theme/app_theme.dart';
import 'auth_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Buat akun baru',
      subtitle:
          'Daftarkan akun pemilik toko. Email akan diverifikasi sebelum akun dipakai.',
      backgroundColor: AppTheme.deepTeal,
      backgroundImage: 'bg login.png',
      frameless: true,
      contentAlignment: const Alignment(0, 0.58),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _fullNameController,
              style: const TextStyle(color: AppTheme.deepTeal),
              decoration: _inputDecoration(
                labelText: 'Nama lengkap',
                prefixIcon: Icons.person_outline_rounded,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppTheme.deepTeal),
              decoration: _inputDecoration(
                labelText: 'Email',
                prefixIcon: Icons.alternate_email_rounded,
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return 'Email wajib diisi';
                }
                if (!text.contains('@')) {
                  return 'Format email belum valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: AppTheme.deepTeal),
              decoration: _inputDecoration(
                labelText: 'Password',
                prefixIcon: Icons.lock_outline_rounded,
              ),
              validator: (value) {
                if ((value ?? '').length < 8) {
                  return 'Password minimal 8 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submitSignUp,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.72),
                  foregroundColor: AppTheme.deepTeal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(_isSubmitting ? 'Membuat akun...' : 'Daftar'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _submitGoogleLogin,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.deepTeal,
                  side: BorderSide(
                    color: AppTheme.deepTeal.withValues(alpha: 0.58),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.account_circle_outlined),
                label: const Text('Daftar dengan Google'),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: _isSubmitting ? null : () => context.go('/login'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.deepTeal,
                ),
                child: const Text('Sudah punya akun? Masuk'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: AppTheme.deepTeal.withValues(alpha: 0.72)),
      prefixIcon: Icon(
        prefixIcon,
        color: AppTheme.deepTeal,
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

  Future<void> _submitSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref.read(authControllerProvider).signUpWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim().isEmpty
                ? null
                : _fullNameController.text.trim(),
          );
      final supabase = Supabase.instance.client;

      final user = supabase.auth.currentUser;

      if (user != null) {
        await _upsertAdminProfile(supabase, {
          'id': user.id,
          'email': user.email,
          'full_name': _fullNameController.text.trim(),
          'role': 'admin',
          'store_owner_user_id': user.id,
        });
      }
      if (!mounted) {
        return;
      }
      context.go('/verify-email');
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

  Future<void> _submitGoogleLogin() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(authControllerProvider).signInWithGoogle();
      ref
          .read(biometricLockControllerProvider)
          .markUnlockedForCurrentSession();
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        final profile = await supabase
            .from('profiles')
            .select('id')
            .eq('id', user.id)
            .maybeSingle();
        if (profile == null) {
          await _upsertAdminProfile(supabase, {
            'id': user.id,
            'email': user.email,
            'full_name': user.userMetadata?['full_name'] as String?,
            'avatar_url': user.userMetadata?['avatar_url'] as String?,
            'role': 'admin',
            'store_owner_user_id': user.id,
          });
        }
      }
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

  Future<void> _upsertAdminProfile(
    SupabaseClient supabase,
    Map<String, Object?> values,
  ) async {
    try {
      await supabase.from('profiles').upsert(values);
    } on PostgrestException catch (error) {
      if (!_isStoreOwnerColumnMissing(error)) {
        rethrow;
      }
      final fallbackValues = Map<String, Object?>.from(values)
        ..remove('store_owner_user_id');
      await supabase.from('profiles').upsert(fallbackValues);
    }
  }

  bool _isStoreOwnerColumnMissing(PostgrestException error) {
    final text = '${error.code} ${error.message}';
    return text.contains('42703') || text.contains('store_owner_user_id');
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
