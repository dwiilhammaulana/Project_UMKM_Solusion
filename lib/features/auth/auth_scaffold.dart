import 'dart:ui';

import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/common_widgets.dart';

class AuthScaffold extends StatefulWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.backgroundColor,
    this.backgroundImage,
    this.frameless = false,
    this.contentAlignment = Alignment.center,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Color? backgroundColor;
  final String? backgroundImage;
  final bool frameless;
  final AlignmentGeometry contentAlignment;

  @override
  State<AuthScaffold> createState() => _AuthScaffoldState();
}

class _AuthScaffoldState extends State<AuthScaffold> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final backgroundImage = widget.backgroundImage;
    if (backgroundImage != null) {
      precacheImage(AssetImage(backgroundImage), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundImage = widget.backgroundImage;

    return Scaffold(
      body: Container(
        decoration: backgroundImage != null
            ? BoxDecoration(
                color: widget.backgroundColor,
                image: DecorationImage(
                  image: AssetImage(backgroundImage),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.08),
                    BlendMode.darken,
                  ),
                ),
              )
            : widget.backgroundColor == null
                ? const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFF9FCFB),
                        Color(0xFFEAF7F4),
                        Color(0xFFFFF6E1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  )
                : BoxDecoration(color: widget.backgroundColor),
        child: SafeArea(
          child: RepaintBoundary(
            child: _AuthGlassCard(
              title: widget.title,
              subtitle: widget.subtitle,
              frameless: widget.frameless,
              alignment: widget.contentAlignment,
              child: widget.child,
            ),
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
    required this.frameless,
    required this.alignment,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool frameless;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final content = _AuthContent(
      title: title,
      subtitle: subtitle,
      titleColor: frameless ? AppTheme.deepTeal : null,
      subtitleColor:
          frameless ? AppTheme.deepTeal.withValues(alpha: 0.78) : null,
      child: child,
    );

    if (frameless) {
      return Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: content,
          ),
        ),
      );
    }

    return Align(
      alignment: alignment,
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
                  color: Colors.white.withValues(alpha: 0.38),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.48),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.midnight.withValues(alpha: 0.06),
                      blurRadius: 40,
                      offset: const Offset(0, 24),
                    ),
                  ],
                ),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthContent extends StatelessWidget {
  const _AuthContent({
    required this.title,
    required this.subtitle,
    required this.child,
    this.titleColor,
    this.subtitleColor,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Color? titleColor;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
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
                    color: AppTheme.deepTeal.withValues(alpha: 0.14),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: const AppIcon(
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
                  color: titleColor ?? AppTheme.deepTeal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: titleColor,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: subtitleColor ?? AppTheme.ink.withValues(alpha: 0.64),
          ),
        ),
        const SizedBox(height: 26),
        child,
      ],
    );
  }
}
