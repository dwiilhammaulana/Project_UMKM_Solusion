import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.currentLocation,
    required this.child,
  });

  final String currentLocation;
  final Widget child;

  static const _adminItems = [
    _NavItem(
      label: 'Beranda',
      path: '/dashboard',
      icon: Icons.home_rounded,
      selectedIcon: Icons.home_filled,
    ),
    _NavItem(
      label: 'Kasir',
      path: '/cashier',
      icon: Icons.point_of_sale_outlined,
      selectedIcon: Icons.point_of_sale_rounded,
    ),
    _NavItem(
      label: 'Produk',
      path: '/products',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2_rounded,
    ),
    _NavItem(
      label: 'Lainnya',
      path: '/more',
      icon: Icons.grid_view_rounded,
      selectedIcon: Icons.widgets_rounded,
    ),
  ];

  static const _cashierItems = [
    _NavItem(
      label: 'Kasir',
      path: '/cashier',
      icon: Icons.point_of_sale_outlined,
      selectedIcon: Icons.point_of_sale_rounded,
    ),
    _NavItem(
      label: 'Produk',
      path: '/products',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2_rounded,
    ),
    _NavItem(
      label: 'BON',
      path: '/debts',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posStateProvider);
    final auth = ref.watch(authControllerProvider);
    final items = auth.isAdmin ? _adminItems : _cashierItems;
    final selectedIndex = _selectedIndex(items);
    final drawBehindStatusBar = currentLocation == '/dashboard' ||
        currentLocation.startsWith('/dashboard/') ||
        currentLocation == '/cashier' ||
        currentLocation.startsWith('/cashier/') ||
        currentLocation == '/products' ||
        currentLocation.startsWith('/products/') ||
        currentLocation == '/more' ||
        currentLocation.startsWith('/more/');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarDividerColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBody: true,
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
          child: Stack(
            children: [
              Positioned(
                top: -120,
                right: -80,
                child: _BackdropOrb(
                  size: 260,
                  color: AppTheme.mint.withValues(alpha: 0.20),
                ),
              ),
              Positioned(
                left: -100,
                top: 120,
                child: _BackdropOrb(
                  size: 220,
                  color: AppTheme.info.withValues(alpha: 0.12),
                ),
              ),
              Positioned(
                right: -100,
                bottom: 120,
                child: _BackdropOrb(
                  size: 240,
                  color: AppTheme.foam,
                ),
              ),
              SafeArea(
                top: !drawBehindStatusBar,
                bottom: false,
                child: state.isLoading
                    ? const LoadingState()
                    : state.errorMessage != null
                        ? ErrorState(
                            title: 'Data aplikasi gagal dimuat',
                            subtitle: state.errorMessage!,
                            onRetry: () => ref.read(posStateProvider).reload(),
                          )
                        : child,
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppTheme.midnight.withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  for (var index = 0; index < items.length; index++)
                    Expanded(
                      child: _BottomNavDestination(
                        key: Key('bottom-nav-${items[index].path}'),
                        item: items[index],
                        selected: index == selectedIndex,
                        onTap: () => context.go(items[index].path),
                      ),
                    ),
                  if (!auth.isAdmin) ...[
                    const SizedBox(width: 6),
                    _SignOutNavButton(
                      onPressed: () =>
                          ref.read(authControllerProvider).signOut(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _selectedIndex(List<_NavItem> items) {
    for (var index = 0; index < items.length; index++) {
      final path = items[index].path;
      if (currentLocation == path || currentLocation.startsWith('$path/')) {
        return index;
      }
    }
    return 0;
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.path,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final String path;
  final IconData icon;
  final IconData selectedIcon;
}

class _BottomNavDestination extends StatelessWidget {
  const _BottomNavDestination({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = selected ? Colors.white : AppTheme.subtext;
    final icon = selected ? item.selectedIcon : item.icon;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: selected ? AppTheme.deepTeal : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              border: selected ? Border.all(color: AppTheme.deepTeal) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(icon, color: foregroundColor, size: 23),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignOutNavButton extends StatelessWidget {
  const _SignOutNavButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Keluar',
      child: SizedBox(
        width: 56,
        height: 58,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          child: const AppIcon(Icons.logout_rounded, size: 22),
        ),
      ),
    );
  }
}

class _BackdropOrb extends StatelessWidget {
  const _BackdropOrb({required this.size, required this.color});

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
