import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  static const _items = [
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

  int get _selectedIndex {
    if (currentLocation.startsWith('/cashier')) return 1;
    if (currentLocation.startsWith('/products')) return 2;
    if (currentLocation.startsWith('/dashboard')) return 0;
    return 3;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posStateProvider);

    return Scaffold(
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
          color: Colors.white.withValues(alpha: 0.96),
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
                for (var index = 0; index < _items.length; index++)
                  Expanded(
                    child: _BottomNavDestination(
                      item: _items[index],
                      selected: index == _selectedIndex,
                      onTap: () => context.go(_items[index].path),
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
                Icon(icon, color: foregroundColor, size: 23),
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
