import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ic.dart';
import 'package:lottie/lottie.dart';

import '../models/app_models.dart';
import '../theme/app_theme.dart';
import '../utils/app_formatters.dart';

class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.color,
    this.size,
    this.visualScale = 0.86,
  });

  final IconData icon;
  final Color? color;
  final double? size;
  final double visualScale;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final resolvedSize = (size ?? iconTheme.size ?? 24) * visualScale;

    return Iconify(
      _iconifyAppIcon(icon),
      color: color ?? iconTheme.color,
      size: resolvedSize,
    );
  }

  static String _iconifyAppIcon(IconData icon) {
    return switch (icon) {
      Icons.account_balance_wallet_rounded => Ic.round_account_balance_wallet,
      Icons.account_circle_outlined => Ic.round_account_circle,
      Icons.add_a_photo_outlined => Ic.round_add_a_photo,
      Icons.add_box_rounded => Ic.round_add_box,
      Icons.add_rounded => Ic.round_add,
      Icons.add_shopping_cart_rounded => Ic.round_add_shopping_cart,
      Icons.admin_panel_settings_rounded => Ic.round_admin_panel_settings,
      Icons.alternate_email_rounded => Ic.round_alternate_email,
      Icons.arrow_back_rounded => Ic.round_arrow_back,
      Icons.arrow_downward_rounded => Ic.round_arrow_downward,
      Icons.arrow_forward_ios_rounded => Ic.round_arrow_forward_ios,
      Icons.arrow_forward_rounded => Ic.round_arrow_forward,
      Icons.arrow_upward_rounded => Ic.round_arrow_upward,
      Icons.bar_chart_rounded => Ic.round_bar_chart,
      Icons.calendar_month_rounded => Ic.round_calendar_month,
      Icons.category_rounded => Ic.round_category,
      Icons.check_circle_rounded => Ic.round_check_circle,
      Icons.check_rounded => Ic.round_check,
      Icons.close_rounded => Ic.round_close,
      Icons.credit_score_rounded => Ic.round_credit_score,
      Icons.delete_outline_rounded => Ic.round_delete_outline,
      Icons.description_rounded => Ic.round_description,
      Icons.done_all_rounded => Ic.round_done_all,
      Icons.done_rounded => Ic.round_done,
      Icons.edit_outlined => Ic.round_edit,
      Icons.emoji_events_rounded => Ic.round_emoji_events,
      Icons.error_outline_rounded => Ic.round_error_outline,
      Icons.fingerprint_rounded => Ic.round_fingerprint,
      Icons.flash_on_rounded => Ic.round_flash_on,
      Icons.grid_view_rounded => Ic.round_grid_view,
      Icons.groups_rounded => Ic.round_groups,
      Icons.history_rounded => Ic.round_history,
      Icons.home_filled => Ic.round_home,
      Icons.home_rounded => Ic.round_home,
      Icons.image_outlined => Ic.round_image,
      Icons.info_outline_rounded => Ic.info_outline,
      Icons.insights_rounded => Ic.round_insights,
      Icons.inventory_2_outlined => Ic.round_inventory_2,
      Icons.inventory_2_rounded => Ic.round_inventory_2,
      Icons.inventory_rounded => Ic.round_inventory,
      Icons.keyboard_arrow_down_rounded => Ic.round_keyboard_arrow_down,
      Icons.list_alt_rounded => Ic.round_list_alt,
      Icons.local_cafe_rounded => Ic.round_local_cafe,
      Icons.local_drink_rounded => Ic.round_local_drink,
      Icons.lock_outline_rounded => Ic.lock_outline,
      Icons.lock_rounded => Ic.round_lock,
      Icons.logout_rounded => Ic.round_logout,
      Icons.manage_accounts_rounded => Ic.round_manage_accounts,
      Icons.note_alt_outlined => Ic.round_note_alt,
      Icons.open_in_new_rounded => Ic.round_open_in_new,
      Icons.payments_outlined => Ic.round_payments,
      Icons.payments_rounded => Ic.round_payments,
      Icons.pending_actions_rounded => Ic.round_pending_actions,
      Icons.people_alt_rounded => Ic.round_people_alt,
      Icons.people_outline_rounded => Ic.round_people_outline,
      Icons.percent_rounded => Ic.round_percent,
      Icons.person_add_alt_1_rounded => Ic.round_person_add_alt_1,
      Icons.person_off_outlined => Ic.round_person_off,
      Icons.person_outline_rounded => Ic.round_person_outline,
      Icons.person_search_rounded => Ic.round_person_search,
      Icons.photo_library_outlined => Ic.round_photo_library,
      Icons.picture_as_pdf_rounded => Ic.round_picture_as_pdf,
      Icons.pie_chart_outline_rounded => Ic.round_pie_chart_outline,
      Icons.point_of_sale_outlined => Ic.round_point_of_sale,
      Icons.point_of_sale_rounded => Ic.round_point_of_sale,
      Icons.print_rounded => Ic.round_print,
      Icons.priority_high_rounded => Ic.round_priority_high,
      Icons.receipt_long_outlined => Ic.round_receipt_long,
      Icons.receipt_long_rounded => Ic.round_receipt_long,
      Icons.receipt_rounded => Ic.round_receipt,
      Icons.refresh_rounded => Ic.round_refresh,
      Icons.remove_rounded => Ic.round_remove,
      Icons.schedule_rounded => Ic.round_schedule,
      Icons.search_off_rounded => Ic.round_search_off,
      Icons.search_rounded => Ic.round_search,
      Icons.sell_outlined => Ic.round_sell,
      Icons.shopping_bag_outlined => Ic.round_shopping_bag,
      Icons.shopping_bag_rounded => Ic.round_shopping_bag,
      Icons.shopping_cart_outlined => Ic.round_shopping_cart,
      Icons.shopping_cart_rounded => Ic.round_shopping_cart,
      Icons.show_chart_rounded => Ic.round_show_chart,
      Icons.stacked_line_chart_rounded => Ic.round_stacked_line_chart,
      Icons.storefront_rounded => Ic.round_storefront,
      Icons.swap_vert_circle_rounded => Ic.round_swap_vertical_circle,
      Icons.trending_up_rounded => Ic.round_trending_up,
      Icons.upload_file_rounded => Ic.round_upload_file,
      Icons.verified_rounded => Ic.round_verified,
      Icons.verified_user_rounded => Ic.round_verified_user,
      Icons.wallet_rounded => Ic.round_wallet,
      Icons.warning_amber_rounded => Ic.round_warning_amber,
      Icons.widgets_rounded => Ic.round_widgets,
      _ => Ic.round_help_outline,
    };
  }
}

const EdgeInsets kPagePadding = EdgeInsets.fromLTRB(20, 20, 20, 20);
const double kShellBottomBarHeight = 74;
const double kShellBottomOverlaySpacing = 20;

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

class AppCleanTopHero extends StatelessWidget {
  const AppCleanTopHero({
    super.key,
    required this.title,
    required this.subtitle,
    this.bottom,
    this.accentIcon,
    this.accentLabel,
    this.accentColor = Colors.white,
    this.heightFactor = 0.40,
    this.minHeight = 300,
    this.maxHeight = 430,
  });

  final String title;
  final String subtitle;
  final Widget? bottom;
  final IconData? accentIcon;
  final String? accentLabel;
  final Color accentColor;
  final double heightFactor;
  final double minHeight;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final heroHeight = (screenHeight * heightFactor).clamp(
      minHeight,
      maxHeight,
    );

    return SizedBox(
      height: heroHeight,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppTheme.deepTeal,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(46),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.midnight.withValues(alpha: 0.22),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(30, topInset + 42, 30, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (accentIcon != null) ...[
                    const SizedBox(width: 18),
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.26),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppIcon(
                            accentIcon!,
                            color: accentColor,
                            size: accentLabel == null ? 34 : 30,
                          ),
                          if (accentLabel != null) ...[
                            const SizedBox(height: 5),
                            Text(
                              accentLabel!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: accentColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (bottom != null) ...[
                const Spacer(),
                bottom!,
              ],
            ],
          ),
        ),
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
            child: AppIcon(icon, color: color),
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
    this.iconColor,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final Color? iconColor;

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
            AppIcon(icon!, size: 14, color: iconColor ?? color),
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
    this.showPrefixIcon = true,
  });

  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final Key? fieldKey;
  final bool showPrefixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: showPrefixIcon
            ? const Padding(
                padding: EdgeInsets.only(left: 8),
                child: AppIcon(Icons.search_rounded, size: 14),
              )
            : null,
        prefixIconConstraints: showPrefixIcon
            ? const BoxConstraints(minWidth: 42, minHeight: 40)
            : null,
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
              child: AppIcon(icon, color: AppTheme.deepTeal),
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
            const AppIcon(Icons.arrow_forward_ios_rounded, size: 16),
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
  final VoidCallback? onTap;
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
                child: AppIcon(icon, color: AppTheme.deepTeal),
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
              trailing ??
                  const AppIcon(Icons.arrow_forward_ios_rounded, size: 16),
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
    this.mediaPlaceholderLabel = 'Upload\nfoto',
  });

  final Product product;
  final String categoryName;
  final VoidCallback onAdd;
  final VoidCallback? onEdit;
  final VoidCallback? onLongPress;
  final int count;
  final String? mediaPlaceholderLabel;

  @override
  Widget build(BuildContext context) {
    final isNasiPaket = categoryName.toLowerCase() == 'nasi paket';
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
                  label: mediaPlaceholderLabel,
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
                            label: isNasiPaket
                                ? (product.isReady ? 'Ready' : 'Kosong')
                                : 'Stok ${product.stockQty} ${product.unit}',
                            color: isNasiPaket
                                ? (product.isReady
                                    ? AppTheme.success
                                    : AppTheme.danger)
                                : (product.isLowStock
                                    ? AppTheme.warning
                                    : AppTheme.success),
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
                    icon: const AppIcon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isNasiPaket && !product.isReady ? null : onAdd,
                    icon: const AppIcon(Icons.add_shopping_cart_rounded),
                    label: Text(
                      isNasiPaket && !product.isReady
                          ? 'Kosong'
                          : (count > 0 ? 'Tambah ($count)' : 'Tambah'),
                    ),
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
    this.maxWidth,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? double.infinity,
        ),
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
                child: AppIcon(icon, size: 34, color: AppTheme.deepTeal),
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
          Lottie.asset(
            'assets/lottie/loading.json',
            width: 112,
            height: 112,
            fit: BoxFit.contain,
            repeat: true,
            errorBuilder: (_, __, ___) => const CircularProgressIndicator(),
          ),
          const SizedBox(height: 10),
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
                  icon: const AppIcon(Icons.refresh_rounded),
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
    } else if (hasPath) {
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
          AppIcon(placeholderIcon,
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
