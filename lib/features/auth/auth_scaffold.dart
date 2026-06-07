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
    this.showBrand = true,
    this.showHeader = true,
    this.resizeToAvoidBottomInset,
    this.keyboardBottomInset = 0,
    this.backgroundAlignment = Alignment.center,
    this.paintBackground = true,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Color? backgroundColor;
  final String? backgroundImage;
  final bool frameless;
  final AlignmentGeometry contentAlignment;
  final bool showBrand;
  final bool showHeader;
  final bool? resizeToAvoidBottomInset;
  final double keyboardBottomInset;
  final AlignmentGeometry backgroundAlignment;
  final bool paintBackground;

  @override
  State<AuthScaffold> createState() => _AuthScaffoldState();
}

class _AuthScaffoldState extends State<AuthScaffold> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final backgroundImage = widget.backgroundImage;
    if (widget.paintBackground && backgroundImage != null) {
      precacheImage(
          _backgroundImageProvider(context, backgroundImage), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundImage = widget.backgroundImage;
    final imageProvider = backgroundImage == null
        ? null
        : _backgroundImageProvider(context, backgroundImage);

    return Scaffold(
      backgroundColor: widget.paintBackground ? null : Colors.transparent,
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: widget.paintBackground && backgroundImage != null
            ? BoxDecoration(
                color: widget.backgroundColor,
                image: DecorationImage(
                  image: imageProvider!,
                  fit: BoxFit.cover,
                  alignment: widget.backgroundAlignment,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.08),
                    BlendMode.darken,
                  ),
                ),
              )
            : !widget.paintBackground
                ? const BoxDecoration()
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
              showBrand: widget.showBrand,
              showHeader: widget.showHeader,
              keyboardBottomInset: widget.keyboardBottomInset,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }

  ImageProvider _backgroundImageProvider(BuildContext context, String asset) {
    final size = MediaQuery.sizeOf(context);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return ResizeImage(
      AssetImage(asset),
      height: (size.height * pixelRatio).round(),
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
    required this.showBrand,
    required this.showHeader,
    required this.keyboardBottomInset,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool frameless;
  final AlignmentGeometry alignment;
  final bool showBrand;
  final bool showHeader;
  final double keyboardBottomInset;

  @override
  Widget build(BuildContext context) {
    final content = _AuthContent(
      title: title,
      subtitle: subtitle,
      titleColor: frameless ? AppTheme.deepTeal : null,
      subtitleColor:
          frameless ? AppTheme.deepTeal.withValues(alpha: 0.78) : null,
      showBrand: showBrand,
      showHeader: showHeader,
      child: child,
    );

    if (frameless) {
      final bottomPadding = 24 + keyboardBottomInset;
      return Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(28, 24, 28, bottomPadding),
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
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + keyboardBottomInset),
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
    required this.showBrand,
    required this.showHeader,
    this.titleColor,
    this.subtitleColor,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBrand;
  final bool showHeader;
  final Color? titleColor;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSubtitle = subtitle.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBrand) ...[
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
        ],
        if (showHeader) ...[
          SizedBox(
            width: double.infinity,
            child: Text(
              title,
              textAlign: showBrand ? TextAlign.start : TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: titleColor,
                height: 1.08,
              ),
            ),
          ),
          if (hasSubtitle) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: Text(
                subtitle,
                textAlign: showBrand ? TextAlign.start : TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: subtitleColor ?? AppTheme.ink.withValues(alpha: 0.64),
                ),
              ),
            ),
          ],
          const SizedBox(height: 26),
        ],
        child,
      ],
    );
  }
}
