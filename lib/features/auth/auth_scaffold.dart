import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';

class AuthScaffold extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F8),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF7FBFA),
              Color(0xFFE7F4F2),
              Color(0xFFF5F7FA),
            ],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -90,
              right: -100,
              child: _SoftOrb(size: 310, color: Color(0xFFB8E8DD)),
            ),
            const Positioned(
              bottom: -155,
              left: -140,
              child: _SoftOrb(size: 360, color: Color(0xFFCADFFA)),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final minHeight = constraints.maxHeight > 48
                      ? constraints.maxHeight - 48
                      : 0.0;
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: minHeight),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: _AuthGlassCard(
                            title: title,
                            subtitle: subtitle,
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftOrb extends StatelessWidget {
  const _SoftOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xE8FFFFFF), Color(0xB8FFFFFF)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepTeal.withValues(alpha: 0.09),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFDDF6F2)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white),
                ),
                child: const Center(
                  child: Text(
                    'TS',
                    style: TextStyle(
                      color: AppTheme.deepTeal,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toko Saku',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Kasir praktis untuk usahamu',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.subtext,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.ink,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              height: 1.12,
              letterSpacing: -0.6,
            ),
          ),
          if (subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.subtext,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}
