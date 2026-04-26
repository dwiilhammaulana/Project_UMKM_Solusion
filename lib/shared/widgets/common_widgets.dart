import 'dart:io';

import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../theme/app_theme.dart';
import '../utils/app_formatters.dart';

const EdgeInsets kPagePadding = EdgeInsets.fromLTRB(20, 20, 20, 20);
const double kShellBottomBarHeight = 74;
const double kShellBottomOverlaySpacing = 44;

double shellBottomClearance(
  BuildContext context, {
  double extraSpacing = 0,
}) {
  return MediaQuery.viewPaddingOf(context).bottom +
      kShellBottomBarHeight +
      kShellBottomOverlaySpacing +
      extraSpacing;
}

class AppPageScrollView extends StatelessWidget {
  const AppPageScrollView({
    super.key,
    required this.children,
    this.padding = kPagePadding,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final basePadding =
        padding is EdgeInsets ? padding as EdgeInsets : kPagePadding;
    final resolvedPadding = EdgeInsets.fromLTRB(
      basePadding.left,
      basePadding.top,
      basePadding.right,
      basePadding.bottom + shellBottomClearance(context),
    );

    return ListView(
      padding: resolvedPadding,
      children: children,
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(subtitle!, style: theme.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: 12),
          action!,
        ],
      ],
    );
  }
}

class HeroPanel extends StatelessWidget {
  const HeroPanel({
    super.key,
    required this.title,
    required this.subtitle,
    this.badge,
    this.trailing,
    this.bottom,
  });

  final String title;
  final String subtitle;
  final Widget? badge;
  final Widget? trailing;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          colors: [AppTheme.midnight, AppTheme.deepTeal, AppTheme.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.midnight.withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -16,
            child: _GlowOrb(
              size: 140,
              color: AppTheme.mint.withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            left: -18,
            bottom: -28,
            child: _GlowOrb(
              size: 120,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (badge != null) ...[
                          badge!,
                          const SizedBox(height: 14),
                        ],
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          subtitle,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 16),
                    trailing!,
                  ],
                ],
              ),
              if (bottom != null) ...[
                const SizedBox(height: 20),
                bottom!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.frostedDecoration(),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.midnight.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const Spacer(),
          Text(title, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.titleLarge),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class DebtAgeIndicator extends StatelessWidget {
  const DebtAgeIndicator({super.key, required this.ageInDays});

  final int ageInDays;

  Color get color {
    if (ageInDays > 14) return AppTheme.danger;
    if (ageInDays >= 4) return AppTheme.warning;
    return AppTheme.success;
  }

  String get label {
    if (ageInDays > 14) return '>14 hari';
    if (ageInDays >= 4) return '4-14 hari';
    return '0-3 hari';
  }

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      label: '$label · $ageInDays hari',
      color: color,
      icon: Icons.schedule_rounded,
    );
  }
}

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.hintText,
    this.onChanged,
    this.controller,
    this.fieldKey,
  });

  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded),
      ),
    );
  }
}

class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      backgroundColor: Colors.white.withValues(alpha: 0.96),
      selectedColor: AppTheme.deepTeal,
      side: BorderSide(
        color: selected
            ? AppTheme.deepTeal
            : AppTheme.deepTeal.withValues(alpha: 0.18),
      ),
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: selected ? Colors.white : AppTheme.deepTeal,
            fontWeight: FontWeight.w800,
          ),
      onSelected: onSelected,
    );
  }
}

class AppActionTile extends StatelessWidget {
  const AppActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.frostedDecoration(
          radius: 26,
          tint: AppTheme.foam,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.deepTeal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: AppTheme.deepTeal),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}

class AppMenuLinkTile extends StatelessWidget {
  const AppMenuLinkTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.frostedDecoration(radius: 24),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.foam,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: AppTheme.deepTeal),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.categoryName,
    required this.onAdd,
    this.onEdit,
    this.onLongPress,
    this.count = 0,
  });

  final Product product;
  final String categoryName;
  final VoidCallback onAdd;
  final VoidCallback? onEdit;
  final VoidCallback? onLongPress;
  final int count;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: AppSectionCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppMediaPreview(
                  imagePath: product.imagePath,
                  width: 96,
                  height: 96,
                  label: 'Upload\nfoto',
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(categoryName),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StatusChip(
                            label: AppFormatters.currency(product.sellPrice),
                            color: AppTheme.deepTeal,
                          ),
                          StatusChip(
                            label: 'Stok ${product.stockQty} ${product.unit}',
                            color: product.isLowStock
                                ? AppTheme.warning
                                : AppTheme.success,
                          ),
                          if ((product.rackLocation ?? '').isNotEmpty)
                            StatusChip(
                              label: product.rackLocation!,
                              color: AppTheme.info,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: Text(count > 0 ? 'Tambah ($count)' : 'Tambah'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title, subtitle: subtitle),
          const SizedBox(height: 16),
          SizedBox(height: 260, child: child),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: AppSectionCard(
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.foam,
              ),
              child: Icon(icon, size: 34, color: AppTheme.deepTeal),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({
    super.key,
    this.label = 'Memuat data lokal...',
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.title,
    required this.subtitle,
    this.onRetry,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: EmptyState(
          icon: Icons.error_outline_rounded,
          title: title,
          subtitle: subtitle,
          action: onRetry == null
              ? null
              : FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Coba Lagi'),
                ),
        ),
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  const SummaryRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class BottomSheetContainer extends StatelessWidget {
  const BottomSheetContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = shellBottomClearance(
          context,
          extraSpacing: MediaQuery.viewInsetsOf(context).bottom,
        ) +
        16;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: bottomPadding,
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: AppTheme.frostedDecoration(radius: 34),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class AppMediaPreview extends StatelessWidget {
  const AppMediaPreview({
    super.key,
    this.imagePath,
    this.width = 88,
    this.height = 88,
    this.placeholderIcon = Icons.image_outlined,
    this.label,
    this.borderRadius = 24,
  });

  final String? imagePath;
  final double width;
  final double height;
  final IconData placeholderIcon;
  final String? label;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final trimmedPath = imagePath?.trim();
    final hasPath = trimmedPath != null && trimmedPath.isNotEmpty;
    final isRemote = hasPath &&
        (trimmedPath.startsWith('http://') ||
            trimmedPath.startsWith('https://'));
    final localExists = hasPath && !isRemote && File(trimmedPath).existsSync();

    Widget child;
    if (isRemote) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          trimmedPath,
          fit: BoxFit.cover,
          width: width,
          height: height,
          errorBuilder: (_, __, ___) => _placeholder(context),
        ),
      );
    } else if (localExists) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.file(
          File(trimmedPath),
          fit: BoxFit.cover,
          width: width,
          height: height,
          errorBuilder: (_, __, ___) => _placeholder(context),
        ),
      );
    } else {
      child = _placeholder(context);
    }

    return SizedBox(width: width, height: height, child: child);
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: const LinearGradient(
          colors: [Color(0xFFE6F2F1), Color(0xFFFDFEFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.deepTeal.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(placeholderIcon,
              color: AppTheme.deepTeal.withValues(alpha: 0.65)),
          if (label != null) ...[
            const SizedBox(height: 6),
            Text(
              label!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class AppProfileAvatar extends StatelessWidget {
  const AppProfileAvatar({
    super.key,
    required this.photoPath,
    this.size = 72,
  });

  final String? photoPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.24),
      ),
      child: ClipOval(
        child: AppMediaPreview(
          imagePath: photoPath,
          width: size,
          height: size,
          borderRadius: size,
          placeholderIcon: Icons.storefront_rounded,
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
