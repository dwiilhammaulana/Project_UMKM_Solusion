import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/auth/auth_controller.dart';
import 'auth_scaffold.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return AuthScaffold(
      title: 'Verifikasi email',
      subtitle:
          'Kami sudah kirim link verifikasi ke ${auth.pendingVerificationEmail ?? auth.emailAddress}. Setelah selesai, masuk kembali ke aplikasi.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Setelah email diverifikasi, kamu bisa login dan lanjut ke onboarding toko.',
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting ? null : () => context.go('/login'),
              child: const Text('Saya sudah verifikasi, kembali ke login'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : _resendVerification,
              child: Text(
                _isSubmitting ? 'Mengirim ulang...' : 'Kirim ulang email verifikasi',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resendVerification() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(authControllerProvider).resendSignupVerification();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email verifikasi dikirim ulang.')),
      );
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
