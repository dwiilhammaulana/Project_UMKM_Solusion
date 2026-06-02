import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

import 'biometric_exception.dart';

abstract class BiometricAuthenticator {
  Future<bool> isBiometricAvailable();
  Future<bool> authenticate({String reason});
}

final biometricServiceProvider = Provider<BiometricAuthenticator>((ref) {
  return BiometricService();
});

class BiometricService implements BiometricAuthenticator {
  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      final biometrics = await _auth.getAvailableBiometrics();
      return canCheckBiometrics && isDeviceSupported && biometrics.isNotEmpty;
    } on LocalAuthException catch (error) {
      final mapped = BiometricException.fromLocalAuthException(error);
      if (mapped.shouldSkipLock) {
        return false;
      }
      rethrow;
    } on PlatformException catch (error) {
      final mapped = BiometricException.fromLegacyCode(
        error.code,
        error.message ?? error.toString(),
      );
      if (mapped.shouldSkipLock) {
        return false;
      }
      rethrow;
    }
  }

  @override
  Future<bool> authenticate({
    String reason = 'Verifikasi identitas untuk membuka Toko Saku.',
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        throw const BiometricException(
          code: BiometricErrorCode.noBiometricHardware,
          message: 'Biometric hardware is unavailable or unenrolled.',
          userMessage:
              'Kunci biometrik belum tersedia di perangkat ini. Aplikasi tetap bisa digunakan.',
        );
      }

      final result = await _auth.authenticate(
        localizedReason: reason,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Verifikasi Diperlukan',
            signInHint: 'Tempelkan jari atau arahkan wajah',
            cancelButton: 'Batal',
          ),
        ],
        biometricOnly: false,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
      );

      if (!result) {
        throw const BiometricException(
          code: BiometricErrorCode.userCanceled,
          message: 'Authentication returned false.',
          userMessage: 'Verifikasi dibatalkan.',
        );
      }
      return true;
    } on BiometricException {
      rethrow;
    } on LocalAuthException catch (error) {
      throw BiometricException.fromLocalAuthException(error);
    } on PlatformException catch (error) {
      throw BiometricException.fromLegacyCode(
        error.code,
        error.message ?? error.toString(),
      );
    }
  }
}
