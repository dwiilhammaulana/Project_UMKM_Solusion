import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';

class AuthFormStyles {
  const AuthFormStyles._();

  static final ButtonStyle primaryButton = FilledButton.styleFrom(
    backgroundColor: AppTheme.deepTeal,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );

  static final ButtonStyle googleButton = OutlinedButton.styleFrom(
    foregroundColor: AppTheme.deepTeal,
    side: BorderSide(
      color: AppTheme.deepTeal.withValues(alpha: 0.18),
    ),
    backgroundColor: Colors.white.withValues(alpha: 0.72),
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );

  static final ButtonStyle textButton = TextButton.styleFrom(
    foregroundColor: AppTheme.deepTeal,
  );
}

InputDecoration authInputDecoration({
  required String labelText,
  required IconData prefixIcon,
  Widget? suffixIcon,
}) {
  final borderRadius = BorderRadius.circular(16);

  return InputDecoration(
    labelText: labelText,
    labelStyle: TextStyle(color: AppTheme.deepTeal.withValues(alpha: 0.72)),
    floatingLabelStyle: const TextStyle(color: AppTheme.deepTeal),
    prefixIcon: Icon(
      prefixIcon,
      color: AppTheme.deepTeal,
      size: 20,
    ),
    prefixIconConstraints: const BoxConstraints(
      minWidth: 48,
      minHeight: 48,
    ),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.82),
    border: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(
        color: AppTheme.deepTeal.withValues(alpha: 0.12),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(
        color: AppTheme.deepTeal.withValues(alpha: 0.12),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: const BorderSide(color: AppTheme.deepTeal, width: 1.4),
    ),
  );
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final lineColor = AppTheme.deepTeal.withValues(alpha: 0.12);
    return Row(
      children: [
        Expanded(child: Divider(color: lineColor, height: 1)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'atau',
            style: TextStyle(color: AppTheme.subtext, fontSize: 12),
          ),
        ),
        Expanded(child: Divider(color: lineColor, height: 1)),
      ],
    );
  }
}

String? validateAuthEmail(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return 'Email wajib diisi';
  }
  if (!text.contains('@')) {
    return 'Format email belum valid';
  }
  return null;
}

String? validateRequiredPassword(String? value, {String label = 'Password'}) {
  if ((value ?? '').isEmpty) {
    return '$label wajib diisi';
  }
  return null;
}

String? validateMinPasswordLength(String? value, {String label = 'Password'}) {
  if ((value ?? '').length < 8) {
    return '$label minimal 8 karakter';
  }
  return null;
}

void showAuthMessage(BuildContext context, String message) {
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
