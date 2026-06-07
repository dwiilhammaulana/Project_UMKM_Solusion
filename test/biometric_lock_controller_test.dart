import 'package:flutter_test/flutter_test.dart';

import 'package:warung_kopi_pos/shared/auth/auth_controller.dart';
import 'package:warung_kopi_pos/shared/biometrics/biometric_exception.dart';
import 'package:warung_kopi_pos/shared/biometrics/biometric_lock_controller.dart';
import 'package:warung_kopi_pos/shared/biometrics/biometric_service.dart';

void main() {
  test('unauthenticated user is never locked', () async {
    final fake = FakeBiometricAuthenticator(isAvailable: true);
    final controller = BiometricLockController(authenticator: fake);

    controller.updateAuthStatus(AuthStatus.unauthenticated);
    await controller.initialize();

    expect(controller.shouldShowLockScreen, isFalse);
    expect(controller.isLocked, isFalse);
  });

  test('fresh login is treated as already unlocked', () async {
    final fake = FakeBiometricAuthenticator(isAvailable: true);
    final controller = BiometricLockController(authenticator: fake);

    controller.updateAuthStatus(AuthStatus.unauthenticated);
    await controller.initialize();
    controller.updateAuthStatus(AuthStatus.authenticated);

    expect(controller.shouldShowLockScreen, isFalse);
    expect(controller.isLocked, isFalse);
  });

  test('fresh login remains unlocked when profile check enters initializing',
      () async {
    final fake = FakeBiometricAuthenticator(isAvailable: true);
    final controller = BiometricLockController(authenticator: fake);

    controller.updateAuthStatus(AuthStatus.unauthenticated);
    await controller.initialize();
    controller.updateAuthStatus(AuthStatus.initializing);
    controller.updateAuthStatus(AuthStatus.authenticated);

    expect(controller.shouldShowLockScreen, isFalse);
    expect(controller.isLocked, isFalse);
  });

  test('fresh login to onboarding is treated as already unlocked', () async {
    final fake = FakeBiometricAuthenticator(isAvailable: true);
    final controller = BiometricLockController(authenticator: fake);

    controller.updateAuthStatus(AuthStatus.unauthenticated);
    await controller.initialize();
    controller.updateAuthStatus(AuthStatus.initializing);
    controller.updateAuthStatus(AuthStatus.needsOnboarding);

    expect(controller.shouldShowLockScreen, isFalse);
    expect(controller.isLocked, isFalse);
  });

  test('restored authenticated session is locked after availability check',
      () async {
    final fake = FakeBiometricAuthenticator(isAvailable: true);
    final controller = BiometricLockController(authenticator: fake);

    controller.updateAuthStatus(AuthStatus.authenticated);
    await controller.initialize();

    expect(controller.shouldShowLockScreen, isTrue);
    expect(controller.isLocked, isTrue);
  });

  test('background shorter than timeout does not lock', () async {
    final clock = FakeClock(DateTime(2026, 1, 1, 10));
    final fake = FakeBiometricAuthenticator(isAvailable: true);
    final controller = BiometricLockController(
      authenticator: fake,
      now: clock.now,
    );

    controller.updateAuthStatus(AuthStatus.unauthenticated);
    await controller.initialize();
    controller.updateAuthStatus(AuthStatus.authenticated);

    controller.handlePaused();
    clock.advance(const Duration(seconds: 29));
    await controller.handleResumed();

    expect(controller.isLocked, isFalse);
    expect(fake.authenticateCallCount, 0);
  });

  test('background at timeout locks and unlocks with biometrics', () async {
    final clock = FakeClock(DateTime(2026, 1, 1, 10));
    final fake = FakeBiometricAuthenticator(isAvailable: true);
    final controller = BiometricLockController(
      authenticator: fake,
      now: clock.now,
    );

    controller.updateAuthStatus(AuthStatus.unauthenticated);
    await controller.initialize();
    controller.updateAuthStatus(AuthStatus.authenticated);

    controller.handlePaused();
    clock.advance(const Duration(seconds: 30));
    await controller.handleResumed();

    expect(controller.isLocked, isFalse);
    expect(controller.shouldShowLockScreen, isFalse);
    expect(fake.authenticateCallCount, 1);
  });

  test('biometric failure keeps app locked with user message', () async {
    final fake = FakeBiometricAuthenticator(
      isAvailable: true,
      authenticateError: const BiometricException(
        code: BiometricErrorCode.userCanceled,
        message: 'Canceled',
        userMessage: 'Verifikasi dibatalkan.',
      ),
    );
    final controller = BiometricLockController(authenticator: fake);

    controller.updateAuthStatus(AuthStatus.authenticated);
    await controller.initialize();
    await controller.unlock();

    expect(controller.isLocked, isTrue);
    expect(controller.shouldShowLockScreen, isTrue);
    expect(controller.errorMessage, 'Verifikasi dibatalkan.');
  });

  test('device without biometrics skips lock to avoid trapping the user',
      () async {
    final fake = FakeBiometricAuthenticator(isAvailable: false);
    final controller = BiometricLockController(authenticator: fake);

    controller.updateAuthStatus(AuthStatus.authenticated);
    await controller.initialize();

    expect(controller.shouldShowLockScreen, isFalse);
    expect(controller.isLocked, isFalse);
  });
}

class FakeClock {
  FakeClock(this.value);

  DateTime value;

  DateTime now() => value;

  void advance(Duration duration) {
    value = value.add(duration);
  }
}

class FakeBiometricAuthenticator implements BiometricAuthenticator {
  FakeBiometricAuthenticator({
    required this.isAvailable,
    this.authenticateError,
  });

  final bool isAvailable;
  final Object? authenticateError;
  int authenticateCallCount = 0;

  @override
  Future<bool> authenticate({String reason = ''}) async {
    authenticateCallCount++;
    final error = authenticateError;
    if (error != null) {
      throw error;
    }
    return true;
  }

  @override
  Future<bool> isBiometricAvailable() async => isAvailable;
}
