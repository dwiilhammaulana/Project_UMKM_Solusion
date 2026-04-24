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

  static const _menuItems = [
    _MenuItem(label: 'Dashboard', path: '/dashboard', icon: Icons.home_rounded),
    _MenuItem(
      label: 'Kasir',
      path: '/cashier',
      icon: Icons.point_of_sale_rounded,
    ),
    _MenuItem(
      label: 'Produk',
      path: '/products',
      icon: Icons.local_cafe_rounded,
    ),
    _MenuItem(
      label: 'Pelanggan',
      path: '/customers',
      icon: Icons.people_alt_rounded,
    ),
    _MenuItem(
      label: 'Bon/Utang',
      path: '/debts',
      icon: Icons.receipt_long_rounded,
    ),
    _MenuItem(
      label: 'Stok',
      path: '/inventory',
      icon: Icons.inventory_2_rounded,
    ),
    _MenuItem(
      label: 'Laporan',
      path: '/reports',
      icon: Icons.description_rounded,
    ),
    _MenuItem(
      label: 'Analitik',
      path: '/analytics',
      icon: Icons.insights_rounded,
    ),
  ];

  String get title {
    for (final item in _menuItems) {
      if (currentLocation == item.path ||
          currentLocation.startsWith('${item.path}/')) {
        return item.label;
      }
    }
    return 'POS Warung Kopi';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posStateProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            key: const Key('app-drawer-button'),
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(title),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 54, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.forest, AppTheme.pine],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.local_cafe_rounded, color: Colors.white),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Warung Kopi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Dummy UI Android untuk gambaran awal operasional POS.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: _menuItems.map((item) {
                  final selected = currentLocation == item.path ||
                      currentLocation.startsWith('${item.path}/');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      key: Key('drawer-${item.label.toLowerCase()}'),
                      selected: selected,
                      selectedTileColor: AppTheme.mist,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      leading: Icon(item.icon),
                      title: Text(item.label),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go(item.path);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.paper, AppTheme.mist],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
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
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.label,
    required this.path,
    required this.icon,
  });

  final String label;
  final String path;
  final IconData icon;
}
