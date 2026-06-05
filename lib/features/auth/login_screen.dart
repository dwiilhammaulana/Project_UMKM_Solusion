import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/auth/auth_controller.dart';
import '../../shared/auth/auth_repository.dart';
import '../../shared/biometrics/biometric_lock_controller.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/common_widgets.dart';
import 'auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Selamat datang di\nToko Saku!',
      subtitle:
          'Gunakan email dan password, atau masuk cepat dengan akun Google.',
      backgroundColor: AppTheme.deepTeal,
      backgroundImage: 'bg login.png',
      frameless: true,
      showBrand: false,
      contentAlignment: const Alignment(0, 0.58),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                if ((value ?? '').isEmpty) {
                  return 'Password wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submitEmailLogin,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.72),
                  foregroundColor: AppTheme.deepTeal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(_isSubmitting ? 'Masuk...' : 'Masuk'),
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
                icon: const AppIcon(Icons.account_circle_outlined),
                label: const Text('Masuk dengan Google'),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: _isSubmitting ? null : () => context.go('/signup'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.deepTeal,
                ),
                child: const Text('Belum punya akun? Daftar'),
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
      prefixIcon: AppIcon(
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

  Future<void> _submitEmailLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auth = ref.read(authControllerProvider);
      await auth.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      ref.read(biometricLockControllerProvider).markUnlockedForCurrentSession();

      if (!mounted) return;
      context.go(auth.isAdmin ? '/dashboard' : '/cashier');
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
      final auth = ref.read(authControllerProvider);
      await auth.signInWithGoogle();
      ref.read(biometricLockControllerProvider).markUnlockedForCurrentSession();

      if (!mounted) return;
      context.go(auth.isAdmin ? '/dashboard' : '/cashier');
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
