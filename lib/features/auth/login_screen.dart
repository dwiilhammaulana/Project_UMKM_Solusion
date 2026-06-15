import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/auth/auth_controller.dart';
import '../../shared/auth/auth_repository.dart';
import '../../shared/biometrics/biometric_lock_controller.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/common_widgets.dart';
import 'auth_form_helpers.dart';
import 'auth_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  double _stableKeyboardInset = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stableKeyboardInset = resolveStableKeyboardInset(
      context,
      _stableKeyboardInset,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = _stableKeyboardInset > 0;

    return AuthScaffold(
      title: 'Selamat datang di\nToko Saku!',
      subtitle:
          'Gunakan email dan password, atau masuk cepat dengan akun Google.',
      backgroundColor: AppTheme.deepTeal,
      backgroundImage: 'bg login.png',
      frameless: true,
      showBrand: false,
      showHeader: !isKeyboardVisible,
      resizeToAvoidBottomInset: false,
      keyboardBottomInset: _stableKeyboardInset,
      backgroundAlignment:
          isKeyboardVisible ? Alignment.topCenter : Alignment.center,
      paintBackground: false,
      contentAlignment: const Alignment(0, 0.58),
      child: const _LoginForm(),
    );
  }
}

class _LoginForm extends ConsumerStatefulWidget {
  const _LoginForm();

  @override
  ConsumerState<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _isSendingPasswordReset = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
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
            obscureText: true,
            style: const TextStyle(color: AppTheme.deepTeal),
            decoration: authInputDecoration(
              labelText: 'Password',
              prefixIcon: Icons.lock_outline_rounded,
            ),
            validator: validateRequiredPassword,
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isSubmitting || _isSendingPasswordReset
                  ? null
                  : _showPasswordResetSheet,
              style: AuthFormStyles.textButton,
              child: const Text('Lupa password?'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submitEmailLogin,
              style: AuthFormStyles.primaryButton,
              child: Text(_isSubmitting ? 'Masuk...' : 'Masuk'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _submitGoogleLogin,
              style: AuthFormStyles.googleButton,
              icon: const AppIcon(Icons.account_circle_outlined, size: 16),
              label: const Text('Masuk dengan Google'),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: _isSubmitting ? null : () => context.go('/signup'),
              style: AuthFormStyles.textButton,
              child: const Text('Belum punya akun? Daftar'),
            ),
          ),
        ],
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
      showAuthMessage(context, error.message);
    } catch (error) {
      showAuthMessage(context, error.toString());
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
      showAuthMessage(context, error.message);
    } catch (error) {
      showAuthMessage(context, error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _showPasswordResetSheet() async {
    final resetFormKey = GlobalKey<FormState>();
    var resetEmail = _emailController.text.trim();
    var isSending = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> submitResetEmail() async {
              if (!resetFormKey.currentState!.validate()) {
                return;
              }

              setState(() => _isSendingPasswordReset = true);
              setSheetState(() => isSending = true);

              try {
                await ref.read(authControllerProvider).sendPasswordResetEmail(
                      resetEmail.trim(),
                    );

                if (!mounted || !sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                showAuthMessage(
                  context,
                  'Link ubah password sudah dikirim ke email kamu.',
                );
              } on AuthFailure catch (error) {
                showAuthMessage(context, error.message);
              } catch (error) {
                showAuthMessage(context, error.toString());
              } finally {
                if (mounted) {
                  setState(() => _isSendingPasswordReset = false);
                }
                if (context.mounted) {
                  setSheetState(() => isSending = false);
                }
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Form(
                    key: resetFormKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const AppIcon(
                              Icons.lock_reset_rounded,
                              color: AppTheme.deepTeal,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Lupa password',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: AppTheme.deepTeal),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Masukkan email akun, lalu cek inbox untuk membuat password baru.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          initialValue: resetEmail,
                          onChanged: (value) => resetEmail = value,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: AppTheme.deepTeal),
                          decoration: authInputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icons.alternate_email_rounded,
                          ),
                          validator: validateAuthEmail,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isSending ? null : submitResetEmail,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.deepTeal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              isSending ? 'Mengirim...' : 'Kirim Email',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: isSending
                                ? null
                                : () => Navigator.of(sheetContext).pop(),
                            style: AuthFormStyles.textButton,
                            child: const Text('Batal'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
