import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/common_widgets.dart';

class AuthFormStyles {
  const AuthFormStyles._();

  static final ButtonStyle primaryButton = FilledButton.styleFrom(
    backgroundColor: Colors.white.withValues(alpha: 0.72),
    foregroundColor: AppTheme.deepTeal,
    padding: const EdgeInsets.symmetric(vertical: 16),
  );

  static final ButtonStyle googleButton = OutlinedButton.styleFrom(
    foregroundColor: AppTheme.deepTeal,
    side: BorderSide(
      color: AppTheme.deepTeal.withValues(alpha: 0.58),
    ),
    padding: const EdgeInsets.symmetric(vertical: 16),
  );

  static final ButtonStyle textButton = TextButton.styleFrom(
    foregroundColor: AppTheme.deepTeal,
  );
}

InputDecoration authInputDecoration({
  required String labelText,
  required IconData prefixIcon,
}) {
  final borderRadius = BorderRadius.circular(18);

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
      borderRadius: borderRadius,
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: 0.72),
        width: 1.4,
      ),
    ),
  );
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

double resolveStableKeyboardInset(BuildContext context, double currentInset) {
  final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
  if (keyboardInset <= 0) {
    return 0;
  }
  if (currentInset > 0) {
    return currentInset;
  }

  final screenHeight = MediaQuery.sizeOf(context).height;
  final estimatedKeyboardInset =
      (screenHeight * 0.38).clamp(260.0, 360.0).toDouble();
  return keyboardInset > estimatedKeyboardInset
      ? keyboardInset
      : estimatedKeyboardInset;
}

void showAuthMessage(BuildContext context, String message) {
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
