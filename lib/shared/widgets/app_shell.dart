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
    final isAdmin = auth.isAdmin;
    final items = isAdmin ? _adminItems : _cashierItems;
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
        drawerEnableOpenDragGesture: !isAdmin,
        drawerEdgeDragWidth: isAdmin ? null : 96,
        drawer: isAdmin
            ? null
            : _CashierDrawer(
                items: _cashierItems,
                selectedIndex: selectedIndex,
                cashierName: auth.displayName ?? auth.emailAddress,
                cashierEmail: auth.emailAddress,
                onSignOut: () => ref.read(authControllerProvider).signOut(),
              ),
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
          child: AppShellChromeScope(
            hasBottomNavigation: isAdmin,
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
                              onRetry: () =>
                                  ref.read(posStateProvider).reload(),
                            )
                          : child,
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: isAdmin
            ? Container(
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      ],
                    ),
                  ),
                ),
              )
            : null,
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

class _CashierDrawer extends StatelessWidget {
  const _CashierDrawer({
    required this.items,
    required this.selectedIndex,
    required this.cashierName,
    required this.cashierEmail,
    required this.onSignOut,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final String cashierName;
  final String cashierEmail;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final displayName = cashierName.trim().isEmpty ? cashierEmail : cashierName;
    final showEmail = cashierEmail.trim().isNotEmpty &&
        cashierEmail.trim().toLowerCase() != displayName.trim().toLowerCase();

    return Drawer(
      width: 304,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [AppTheme.midnight, AppTheme.deepTeal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    if (showEmail) ...[
                      const SizedBox(height: 4),
                      Text(
                        cashierEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    const StatusChip(
                      label: 'Kasir',
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            for (var index = 0; index < items.length; index++)
              _CashierDrawerItem(
                key: Key('cashier-sidebar-${items[index].path}'),
                item: items[index],
                selected: index == selectedIndex,
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
              child: _CashierDrawerSignOutButton(onSignOut: onSignOut),
            ),
          ],
        ),
      ),
    );
  }
}

class _CashierDrawerItem extends StatelessWidget {
  const _CashierDrawerItem({
    super.key,
    required this.item,
    required this.selected,
  });

  final _NavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = selected ? Colors.white : AppTheme.deepTeal;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: selected ? AppTheme.deepTeal : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            final router = GoRouter.of(context);
            Navigator.of(context).pop();
            router.go(item.path);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: foregroundColor,
                          fontWeight: FontWeight.w900,
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

class _CashierDrawerSignOutButton extends StatelessWidget {
  const _CashierDrawerSignOutButton({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      key: const Key('cashier-sidebar-sign-out'),
      onPressed: () {
        Navigator.of(context).pop();
        onSignOut();
      },
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: const Text('Keluar'),
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
