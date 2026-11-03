import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/auth/auth_controller.dart';
import '../../shared/auth/auth_repository.dart';
import '../../shared/biometrics/biometric_lock_controller.dart';
import '../../shared/theme/app_theme.dart';

import 'auth_form_helpers.dart';
import 'auth_scaffold.dart';

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
  bool _showPassword = false;

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
      subtitle: 'Mulai kelola tokomu dengan satu akun.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _fullNameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              style: const TextStyle(color: AppTheme.deepTeal),
              decoration: authInputDecoration(
                labelText: 'Nama lengkap',
                prefixIcon: Icons.person_outline_rounded,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              style: const TextStyle(color: AppTheme.deepTeal),
              decoration: authInputDecoration(
                labelText: 'Email',
                prefixIcon: Icons.alternate_email_rounded,
              ),
              validator: validateAuthEmail,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: !_showPassword,
              autofillHints: const [AutofillHints.newPassword],
              style: const TextStyle(color: AppTheme.deepTeal),
              decoration: authInputDecoration(
                labelText: 'Password',
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  tooltip:
                      _showPassword ? 'Sembunyikan password' : 'Lihat password',
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                ),
              ),
              validator: validateMinPasswordLength,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submitSignUp,
                style: AuthFormStyles.primaryButton,
                child: Text(_isSubmitting ? 'Membuat akun...' : 'Daftar'),
              ),
            ),
            const SizedBox(height: 18),
            const AuthDivider(),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _submitGoogleLogin,
                style: AuthFormStyles.googleButton,
                icon: const Text('G',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                label: const Text('Daftar dengan Google'),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: _isSubmitting ? null : () => context.go('/login'),
                style: AuthFormStyles.textButton,
                child: const Text('Sudah punya akun? Masuk'),
              ),
            ),
          ],
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
      if (mounted) {
        showAuthMessage(context, error.message);
      }
    } catch (error) {
      if (mounted) {
        showAuthMessage(context, error.toString());
      }
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
      ref.read(biometricLockControllerProvider).markUnlockedForCurrentSession();
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
      if (mounted) {
        showAuthMessage(context, error.message);
      }
    } catch (error) {
      if (mounted) {
        showAuthMessage(context, error.toString());
      }
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
}
