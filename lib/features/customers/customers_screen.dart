import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/state/app_state.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/app_formatters.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/customer_form_sheet.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(posStateProvider);
    final filtered = state.customers.where((customer) {
      final input = _query.toLowerCase();
      return customer.name.toLowerCase().contains(input) ||
          customer.phone.toLowerCase().contains(input);
    }).toList();

    return AppPageScrollView(
      children: [
        HeroPanel(
          badge: const StatusChip(
            label: 'Pelanggan',
            color: Colors.white,
            icon: Icons.people_alt_rounded,
          ),
          title: 'Kelola pelanggan aktif untuk transaksi BON.',
          subtitle:
              'Cari pelanggan, tambah data baru, lalu buka profil riwayat transaksi mereka.',
          bottom: FilledButton.icon(
            key: const Key('customers-add-button'),
            onPressed: () async => showCustomerFormSheet(context, ref),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Tambah Pelanggan'),
          ),
        ),
        const SizedBox(height: 20),
        AppSectionCard(
          child: AppSearchField(
            fieldKey: const Key('customers-search-field'),
            hintText: 'Cari nama atau nomor telepon',
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        const SizedBox(height: 20),
        if (filtered.isEmpty)
          const EmptyState(
            icon: Icons.people_outline_rounded,
            title: 'Belum ada pelanggan cocok',
            subtitle: 'Tambah pelanggan baru agar bisa dipakai di transaksi BON.',
          )
        else
          ...filtered.map((customer) {
            final totalPurchase = state.totalPurchaseByCustomer(customer.id);
            final activeDebt = state.activeDebtByCustomer(customer.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const AppMediaPreview(
                          width: 62,
                          height: 62,
                          borderRadius: 31,
                          placeholderIcon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text('${customer.phone} · ${customer.address}'),
                            ],
                          ),
                        ),
                        StatusChip(
                          label: customer.isActive ? 'Aktif' : 'Nonaktif',
                          color: customer.isActive
                              ? AppTheme.success
                              : AppTheme.info,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusChip(
                          label:
                              'Belanja ${AppFormatters.currency(totalPurchase)}',
                          color: AppTheme.info,
                        ),
                        StatusChip(
                          label: 'Utang ${AppFormatters.currency(activeDebt)}',
                          color: activeDebt > 0
                              ? AppTheme.warning
                              : AppTheme.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => showCustomerFormSheet(
                              context,
                              ref,
                              customer: customer,
                            ),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await ref
                                  .read(posStateProvider)
                                  .toggleCustomerActive(customer.id);
                            },
                            icon: Icon(
                              customer.isActive
                                  ? Icons.person_off_outlined
                                  : Icons.person_outline_rounded,
                            ),
                            label: Text(
                              customer.isActive ? 'Nonaktifkan' : 'Aktifkan',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () => context.go('/customers/${customer.id}'),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Buka Profil'),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
