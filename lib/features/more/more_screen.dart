import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/state/app_state.dart';
import '../../shared/utils/app_formatters.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/store_profile_sheet.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                subtitle: '${profile.ownerName ?? 'Pemilik toko'} · ${profile.storeSubtitle}',
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
      ],
    );
  }
}
