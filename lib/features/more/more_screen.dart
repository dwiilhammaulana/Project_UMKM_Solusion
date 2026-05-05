import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/auth/auth_controller.dart';
import '../../shared/state/app_state.dart';
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
      children: [
        HeroPanel(
          badge: const StatusChip(
            label: 'Lainnya',
            color: Colors.white,
            icon: Icons.auto_awesome_rounded,
          ),
          title: 'Kontrol lengkap operasional toko.',
          subtitle:
              'Akses modul pelanggan, bon, stok, laporan, dan analitik dari satu hub yang rapi.',
          trailing: AppProfileAvatar(photoPath: profile.photoPath, size: 68),
          bottom: FilledButton.icon(
            onPressed: () => showStoreProfileSheet(
              context,
              ref,
              profile: profile,
            ),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Edit profil toko'),
          ),
        ),
        const SizedBox(height: 20),
        AppSectionCard(
          child: Column(
            children: [
              SectionHeader(
                title: profile.storeName,
                subtitle:
                    '${profile.ownerName ?? 'Pemilik toko'} · ${profile.storeSubtitle}',
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
        const SizedBox(height: 20),
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
              : const Icon(Icons.logout_rounded, size: 20),
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
