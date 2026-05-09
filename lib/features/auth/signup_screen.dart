import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/auth/auth_controller.dart';
import '../../shared/auth/auth_repository.dart';
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
  String _selectedRole = 'kasir';

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
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Nama lengkap'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
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
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (value) {
                if ((value ?? '').length < 8) {
                  return 'Password minimal 8 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pilih Role',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRole = 'admin';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedRole == 'admin'
                            ? Colors.teal.withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedRole == 'admin'
                              ? Colors.teal
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: const [
                          Icon(
                            Icons.admin_panel_settings,
                            size: 40,
                            color: Colors.teal,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Admin',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRole = 'kasir';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedRole == 'kasir'
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedRole == 'kasir'
                              ? Colors.orange
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: const [
                          Icon(
                            Icons.point_of_sale,
                            size: 40,
                            color: Colors.orange,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Kasir',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submitSignUp,
                child: Text(_isSubmitting ? 'Membuat akun...' : 'Daftar'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _submitGoogleLogin,
                icon: const Icon(Icons.account_circle_outlined),
                label: const Text('Daftar dengan Google'),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: _isSubmitting ? null : () => context.go('/login'),
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
        await supabase.from('profiles').upsert({
          'id': user.id,
          'email': user.email,
          'full_name': _fullNameController.text.trim(),
          'role': _selectedRole,
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
