import 'package:local_auth/local_auth.dart';

enum BiometricErrorCode {
  noBiometricHardware,
  notEnrolled,
  temporaryLockout,
  biometricLockout,
  userCanceled,
  systemCanceled,
  unknown,
}

class BiometricException implements Exception {
  const BiometricException({
    required this.code,
    required this.message,
    required this.userMessage,
  });

  factory BiometricException.fromLocalAuthException(LocalAuthException error) {
    final message = error.description ?? error.toString();
    return switch (error.code) {
      LocalAuthExceptionCode.noBiometricHardware => BiometricException(
          code: BiometricErrorCode.noBiometricHardware,
          message: message,
          userMessage:
              'Perangkat ini belum mendukung kunci biometrik yang aman.',
        ),
      LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable =>
        BiometricException(
          code: BiometricErrorCode.noBiometricHardware,
          message: message,
          userMessage:
              'Kunci biometrik perangkat sedang tidak tersedia saat ini.',
        ),
      LocalAuthExceptionCode.noBiometricsEnrolled => BiometricException(
          code: BiometricErrorCode.notEnrolled,
          message: message,
          userMessage:
              'Belum ada sidik jari atau wajah yang terdaftar di perangkat.',
        ),
      LocalAuthExceptionCode.noCredentialsSet => BiometricException(
          code: BiometricErrorCode.notEnrolled,
          message: message,
          userMessage:
              'Belum ada kunci layar, sidik jari, atau wajah yang terdaftar.',
        ),
      LocalAuthExceptionCode.temporaryLockout => BiometricException(
          code: BiometricErrorCode.temporaryLockout,
          message: message,
          userMessage:
              'Verifikasi terkunci sementara. Tunggu sebentar lalu coba lagi.',
        ),
      LocalAuthExceptionCode.biometricLockout => BiometricException(
          code: BiometricErrorCode.biometricLockout,
          message: message,
          userMessage:
              'Biometrik terkunci. Buka kunci perangkat dengan PIN/pola dulu.',
        ),
      LocalAuthExceptionCode.userCanceled => BiometricException(
          code: BiometricErrorCode.userCanceled,
          message: message,
          userMessage: 'Verifikasi dibatalkan.',
        ),
      LocalAuthExceptionCode.systemCanceled => BiometricException(
          code: BiometricErrorCode.systemCanceled,
          message: message,
          userMessage:
              'Verifikasi dibatalkan oleh sistem. Silakan coba lagi.',
        ),
      LocalAuthExceptionCode.timeout => BiometricException(
          code: BiometricErrorCode.systemCanceled,
          message: message,
          userMessage:
              'Waktu verifikasi habis. Tekan Buka Kunci untuk mencoba lagi.',
        ),
      _ => BiometricException(
          code: BiometricErrorCode.unknown,
          message: message,
          userMessage: 'Verifikasi biometrik gagal. Silakan coba lagi.',
        ),
    };
  }

  factory BiometricException.fromLegacyCode(String code, String message) {
    final normalizedCode = code.toLowerCase();
    if (normalizedCode.contains('notavailable') ||
        normalizedCode.contains('not_available')) {
      return BiometricException(
          code: BiometricErrorCode.noBiometricHardware,
          message: message,
          userMessage:
              'Perangkat ini belum mendukung kunci biometrik yang aman.',
        );
    }
    if (normalizedCode.contains('notenrolled') ||
        normalizedCode.contains('not_enrolled')) {
      return BiometricException(
          code: BiometricErrorCode.notEnrolled,
          message: message,
          userMessage:
              'Belum ada sidik jari atau wajah yang terdaftar di perangkat.',
        );
    }
    if (normalizedCode.contains('lockedout') ||
        normalizedCode.contains('locked_out')) {
      return BiometricException(
          code: BiometricErrorCode.temporaryLockout,
          message: message,
          userMessage:
              'Verifikasi terkunci sementara. Tunggu sebentar lalu coba lagi.',
        );
    }
    if (normalizedCode.contains('permanently')) {
      return BiometricException(
          code: BiometricErrorCode.biometricLockout,
          message: message,
          userMessage:
              'Biometrik terkunci. Buka kunci perangkat dengan PIN/pola dulu.',
        );
    }
    return BiometricException(
      code: BiometricErrorCode.unknown,
      message: message,
      userMessage: 'Verifikasi biometrik gagal. Silakan coba lagi.',
    );
  }

  final BiometricErrorCode code;
  final String message;
  final String userMessage;

  bool get isRetryable =>
      code == BiometricErrorCode.userCanceled ||
      code == BiometricErrorCode.systemCanceled ||
      code == BiometricErrorCode.temporaryLockout ||
      code == BiometricErrorCode.unknown;

  bool get requiresSettings => code == BiometricErrorCode.notEnrolled;

  bool get shouldSkipLock =>
      code == BiometricErrorCode.noBiometricHardware ||
      code == BiometricErrorCode.notEnrolled;

  @override
  String toString() => userMessage;
}
