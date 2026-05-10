import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';

class AuthScaffold extends StatefulWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  State<AuthScaffold> createState() => _AuthScaffoldState();
}

class _AuthScaffoldState extends State<AuthScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motionController;

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..forward();
  }

  @override
  void dispose() {
    _motionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF9FCFB),
              Color(0xFFEAF7F4),
              Color(0xFFFFF6E1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _motionController,
            child: RepaintBoundary(
              child: _AuthGlassCard(
                title: widget.title,
                subtitle: widget.subtitle,
                child: widget.child,
              ),
            ),
            builder: (context, child) {
              final phase = _motionController.value * math.pi * 2;
              return Stack(
                children: [
                  Positioned(
                    top: 28 + math.sin(phase) * 14,
                    left: -84 + math.cos(phase * 0.8) * 18,
                    child: _GlassAccentBand(
                      width: 260,
                      height: 112,
                      color: AppTheme.mint,
                      angle: -0.28 + math.sin(phase * 0.7) * 0.04,
                    ),
                  ),
                  Positioned(
                    right: -74 + math.sin(phase * 0.75) * 20,
                    bottom: 72 + math.cos(phase * 0.9) * 16,
                    child: _GlassAccentBand(
                      width: 300,
                      height: 126,
                      color: const Color(0xFFFFD66B),
                      angle: -0.18 + math.cos(phase * 0.65) * 0.035,
                    ),
                  ),
                  Positioned(
                    top: 126 + math.cos(phase * 0.85) * 10,
                    right: 26 + math.sin(phase * 0.7) * 14,
                    child: Transform.rotate(
                      angle: math.sin(phase * 0.6) * 0.03,
                      child: Container(
                        width: 112,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  child!,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AuthGlassCard extends StatelessWidget {
  const _AuthGlassCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.midnight.withValues(alpha: 0.10),
                      blurRadius: 40,
                      offset: const Offset(0, 24),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFFFFFF),
                                Color(0xFFDDF6F2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.86),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppTheme.deepTeal.withValues(alpha: 0.14),
                                blurRadius: 24,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_cafe_rounded,
                            color: AppTheme.deepTeal,
                            size: 31,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Toko Saku',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppTheme.deepTeal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.ink.withValues(alpha: 0.64),
                      ),
                    ),
                    const SizedBox(height: 26),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassAccentBand extends StatelessWidget {
  const _GlassAccentBand({
    required this.width,
    required this.height,
    required this.color,
    required this.angle,
  });

  final double width;
  final double height;
  final Color color;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(44),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(44),
              border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
            ),
          ),
        ),
      ),
    );
  }
}
