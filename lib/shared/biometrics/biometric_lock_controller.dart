import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'biometric_exception.dart';
import 'biometric_service.dart';

typedef DateTimeReader = DateTime Function();

final biometricLockControllerProvider =
    ChangeNotifierProvider<BiometricLockController>((ref) {
  final controller = BiometricLockController(
    authenticator: ref.watch(biometricServiceProvider),
  );
  final initialAuth = ref.read(authControllerProvider);
  controller.updateAuthStatus(initialAuth.status);
  unawaited(controller.initialize());

  ref.listen<AuthController>(authControllerProvider, (previous, next) {
    controller.updateAuthStatus(next.status);
  });

  return controller;
});

class BiometricLockController extends ChangeNotifier {
  BiometricLockController({
    required BiometricAuthenticator authenticator,
    DateTimeReader? now,
    this.lockTimeout = const Duration(seconds: 30),
  })  : _authenticator = authenticator,
        _now = now ?? DateTime.now;

  final BiometricAuthenticator _authenticator;
  final DateTimeReader _now;
  final Duration lockTimeout;

  AuthStatus _authStatus = AuthStatus.initializing;
  bool _isAvailabilityChecked = false;
  bool _isBiometricAvailable = false;
  bool _isLocked = false;
  bool _isUnlocking = false;
  bool _unlockedForCurrentSession = false;
  bool _hasObservedUnauthenticated = false;
  String? _errorMessage;
  DateTime? _backgroundedAt;
  Future<void>? _availabilityFuture;

  bool get isLocked => _isLocked;
  bool get isUnlocking => _isUnlocking;
  bool get isBiometricAvailable => _isBiometricAvailable;
  bool get isAvailabilityChecked => _isAvailabilityChecked;
  String? get errorMessage => _errorMessage;
  bool get protectsCurrentRoute => _isProtectedStatus(_authStatus);

  bool get shouldShowLockScreen {
    if (!_isProtectedStatus(_authStatus)) {
      return false;
    }
    if (_isLocked) {
      return true;
    }
    if (!_isAvailabilityChecked && !_unlockedForCurrentSession) {
      return true;
    }
    return _isAvailabilityChecked &&
        _isBiometricAvailable &&
        !_unlockedForCurrentSession;
  }

  Future<void> initialize() async {
    if (_isAvailabilityChecked) {
      return;
    }
    final pending = _availabilityFuture;
    if (pending != null) {
      return pending;
    }

    final future = _initializeAvailability();
    _availabilityFuture = future;
    return future;
  }

  Future<void> _initializeAvailability() async {
    try {
      _isBiometricAvailable = await _authenticator.isBiometricAvailable();
    } on BiometricException catch (error) {
      _errorMessage = error.shouldSkipLock ? null : error.userMessage;
      _isBiometricAvailable = false;
    } catch (error) {
      _errorMessage = 'Kunci biometrik belum bisa dipakai saat ini.';
      _isBiometricAvailable = false;
    } finally {
      _isAvailabilityChecked = true;
      _availabilityFuture = null;
      _applyProtectedSessionPolicy();
      notifyListeners();
    }
  }

  void updateAuthStatus(AuthStatus status) {
    if (_authStatus == status) {
      return;
    }

    _authStatus = status;

    if (!_isProtectedStatus(status)) {
      if (status == AuthStatus.unauthenticated) {
        _hasObservedUnauthenticated = true;
      }
      _resetSessionLock();
      notifyListeners();
      return;
    }

    if (_hasObservedUnauthenticated) {
      markUnlockedForCurrentSession();
      return;
    }

    _applyProtectedSessionPolicy();
    notifyListeners();
  }

  void markUnlockedForCurrentSession() {
    _unlockedForCurrentSession = true;
    _hasObservedUnauthenticated = false;
    _isLocked = false;
    _isUnlocking = false;
    _errorMessage = null;
    notifyListeners();
  }

  void handlePaused() {
    if (!_isProtectedStatus(_authStatus)) {
      return;
    }
    _backgroundedAt = _now();
  }

  Future<void> handleResumed() async {
    if (!_isProtectedStatus(_authStatus)) {
      return;
    }

    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    if (backgroundedAt == null) {
      return;
    }

    if (_now().difference(backgroundedAt) < lockTimeout) {
      return;
    }

    lock();
    await unlock();
  }

  void lock() {
    if (!_isProtectedStatus(_authStatus) || !_isBiometricAvailable) {
      return;
    }
    _isLocked = true;
    _unlockedForCurrentSession = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> unlock() async {
    if (!_isProtectedStatus(_authStatus)) {
      return;
    }
    if (!_isAvailabilityChecked) {
      await initialize();
    }
    if (!_isBiometricAvailable) {
      markUnlockedForCurrentSession();
      return;
    }

    _isLocked = true;
    _isUnlocking = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authenticator.authenticate(
        reason: 'Verifikasi identitas untuk membuka Toko Saku.',
      );
      _unlockedForCurrentSession = true;
      _isLocked = false;
      _errorMessage = null;
    } on BiometricException catch (error) {
      if (error.shouldSkipLock) {
        _unlockedForCurrentSession = true;
        _isLocked = false;
        _errorMessage = null;
      } else {
        _errorMessage = error.userMessage;
      }
    } catch (error) {
      _errorMessage = 'Verifikasi biometrik gagal. Silakan coba lagi.';
    } finally {
      _isUnlocking = false;
      notifyListeners();
    }
  }

  void _applyProtectedSessionPolicy() {
    if (!_isProtectedStatus(_authStatus) ||
        !_isAvailabilityChecked ||
        !_isBiometricAvailable ||
        _unlockedForCurrentSession) {
      return;
    }
    _isLocked = true;
  }

  void _resetSessionLock() {
    _isLocked = false;
    _isUnlocking = false;
    _unlockedForCurrentSession = false;
    _errorMessage = null;
    _backgroundedAt = null;
  }

  bool _isProtectedStatus(AuthStatus status) {
    return status == AuthStatus.authenticated ||
        status == AuthStatus.needsOnboarding;
  }
}
