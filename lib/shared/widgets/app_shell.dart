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
                          title: 'Database lokal gagal dimuat',
                          subtitle: state.errorMessage!,
                          onRetry: () => ref.read(posStateProvider).reload(),
                        )
                      : child,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          decoration: AppTheme.frostedDecoration(radius: 30),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            destinations: _items
                .map(
                  (item) => NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: item.label,
                  ),
                )
                .toList(),
            onDestinationSelected: (index) => context.go(_items[index].path),
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
