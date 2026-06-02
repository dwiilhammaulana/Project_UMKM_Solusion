import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'biometric_lock_controller.dart';

class BiometricLockGate extends ConsumerStatefulWidget {
  const BiometricLockGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<BiometricLockGate> createState() => _BiometricLockGateState();
}

class _BiometricLockGateState extends ConsumerState<BiometricLockGate>
    with WidgetsBindingObserver {
  bool _autoUnlockQueued = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(biometricLockControllerProvider);
    if (state == AppLifecycleState.paused) {
      controller.handlePaused();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      unawaited(controller.handleResumed());
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(biometricLockControllerProvider);
    if (!controller.shouldShowLockScreen) {
      _autoUnlockQueued = false;
      return widget.child;
    }

    _queueInitialUnlock(controller);
    return _BiometricLockScreen(controller: controller);
  }

  void _queueInitialUnlock(BiometricLockController controller) {
    if (_autoUnlockQueued ||
        controller.isUnlocking ||
        controller.errorMessage != null) {
      return;
    }
    _autoUnlockQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(ref.read(biometricLockControllerProvider).unlock());
    });
  }
}

class _BiometricLockScreen extends StatelessWidget {
  const _BiometricLockScreen({required this.controller});

  final BiometricLockController controller;

  @override
  Widget build(BuildContext context) {
    final errorMessage = controller.errorMessage;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: DecoratedBox(
                  decoration: AppTheme.frostedDecoration(radius: 28),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            color: AppTheme.foam,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: const AppIcon(
                            Icons.lock_rounded,
                            color: AppTheme.deepTeal,
                            size: 42,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Aplikasi Terkunci',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Verifikasi biometrik atau kunci perangkat untuk membuka Toko Saku.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.danger.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              errorMessage,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppTheme.danger),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          key: const Key('biometric-unlock-button'),
                          onPressed:
                              controller.isUnlocking ? null : controller.unlock,
                          icon: controller.isUnlocking
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : const AppIcon(Icons.fingerprint_rounded),
                          label: Text(
                            controller.isUnlocking
                                ? 'Memverifikasi...'
                                : 'Buka Kunci',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
