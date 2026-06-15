import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/auth/auth_controller.dart';
import '../../shared/models/app_models.dart';
import '../../shared/state/app_state.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/app_formatters.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/store_profile_sheet.dart';

class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {
  bool _isSigningOut = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(posStateProvider);
    final profile = state.appProfile;

    return AppPageScrollView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
      children: [
        _MoreHero(
          profile: profile,
          onEditProfile: () => showStoreProfileSheet(
            context,
            ref,
            profile: profile,
          ),
          onOpenUsers: () => context.go('/users'),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AppSectionCard(
            child: Column(
              children: [
                SectionHeader(
                  title: profile.storeName,
                  subtitle:
                      '${profile.ownerName ?? 'Pemilik toko'} - ${profile.storeSubtitle}',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 158,
                  child: Row(
                    children: [
                      Expanded(
                        child: KpiCard(
                          title: 'Pelanggan',
                          value: '${state.customers.length}',
                          icon: Icons.people_alt_rounded,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: KpiCard(
                          title: 'Bon Aktif',
                          value: AppFormatters.currency(state.activeDebtTotal),
                          icon: Icons.wallet_rounded,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              AppMenuLinkTile(
                key: const Key('more-customers-link'),
                icon: Icons.people_alt_rounded,
                title: 'Pelanggan',
                subtitle: 'Cari, edit, dan lihat riwayat pelanggan.',
                onTap: () => context.go('/customers'),
              ),
              AppMenuLinkTile(
                key: const Key('more-debts-link'),
                icon: Icons.receipt_long_rounded,
                title: 'Bon / Utang',
                subtitle: 'Pantau tagihan aktif dan input cicilan.',
                onTap: () => context.go('/debts'),
              ),
              AppMenuLinkTile(
                key: const Key('more-inventory-link'),
                icon: Icons.inventory_2_rounded,
                title: 'Stok & Inventory',
                subtitle: 'Lihat stok menipis dan pergerakan barang.',
                onTap: () => context.go('/inventory'),
              ),
              AppMenuLinkTile(
                key: const Key('more-reports-link'),
                icon: Icons.description_rounded,
                title: 'Laporan',
                subtitle: 'Ringkasan laporan berkala dan export placeholder.',
                onTap: () => context.go('/reports'),
              ),
              AppMenuLinkTile(
                key: const Key('more-analytics-link'),
                icon: Icons.insights_rounded,
                title: 'Analitik',
                subtitle: 'Visual performa usaha dalam chart.',
                onTap: () => context.go('/analytics'),
              ),
              AppMenuLinkTile(
                key: const Key('more-users-link'),
                icon: Icons.manage_accounts_rounded,
                title: 'Kelola Akun',
                subtitle: 'Lihat user toko dan buat akun kasir karyawan.',
                onTap: () => context.go('/users'),
              ),
              AppMenuLinkTile(
                key: const Key('more-logout-button'),
                icon: Icons.logout_rounded,
                title: 'Keluar',
                subtitle: 'Akhiri sesi akun dan kembali ke halaman login.',
                onTap: _isSigningOut ? null : _confirmSignOut,
                trailing: _isSigningOut
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : const AppIcon(Icons.logout_rounded, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Keluar dari aplikasi?'),
          content: const Text(
            'Sesi akun akan diakhiri dan kamu perlu login lagi untuk masuk.',
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actions: [
            SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Keluar'),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Batal'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isSigningOut = true);
    try {
      await ref.read(authControllerProvider).signOut();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }
}

class _MoreHero extends StatelessWidget {
  const _MoreHero({
    required this.profile,
    required this.onEditProfile,
    required this.onOpenUsers,
  });

  final AppProfile profile;
  final VoidCallback onEditProfile;
  final VoidCallback onOpenUsers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final heroHeight = (screenHeight * 0.44).clamp(320.0, 430.0);

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
                            'Lainnya',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Kontrol lengkap operasional toko.',
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
                  const SizedBox(width: 18),
                  AppProfileEditAvatar(
                    photoPath: profile.photoPath,
                    onEditProfile: onEditProfile,
                    size: 84,
                  ),
                ],
              ),
              const Spacer(),
              _MoreHeroButton(
                label: 'Edit profil',
                onPressed: onEditProfile,
                filled: true,
              ),
              const SizedBox(height: 14),
              _MoreHeroButton(
                label: 'Kelola akun',
                onPressed: onOpenUsers,
                filled: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreHeroButton extends StatelessWidget {
  const _MoreHeroButton({
    required this.label,
    required this.onPressed,
    required this.filled,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final background = filled ? Colors.white : Colors.transparent;
    final foreground = filled ? AppTheme.deepTeal : Colors.white;

    return SizedBox(
      width: double.infinity,
      height: 62,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.94),
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
