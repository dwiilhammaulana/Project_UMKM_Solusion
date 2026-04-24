import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/app_models.dart';
import '../../shared/state/app_state.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/app_formatters.dart';
import '../../shared/widgets/common_widgets.dart';

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posStateProvider);
    final matches = state.customers.where(
      (customer) => customer.id == customerId,
    );
    if (matches.isEmpty) {
      return const EmptyState(
        icon: Icons.person_search_rounded,
        title: 'Pelanggan tidak ditemukan',
        subtitle: 'Coba kembali ke daftar pelanggan dan pilih data lain.',
      );
    }

    final customer = matches.first;
    final transactions = state.transactionsByCustomer(customerId);
    final debts = state.debtsByCustomer(customerId);
    final payments = state.paymentsByCustomer(customerId);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text('${customer.phone} - ${customer.address}'),
              if ((customer.notes ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(customer.notes!),
              ],
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.35,
                children: [
                  KpiCard(
                    title: 'Total Belanja',
                    value: AppFormatters.currency(
                      state.totalPurchaseByCustomer(customerId),
                    ),
                    icon: Icons.shopping_cart_rounded,
                    color: AppTheme.info,
                  ),
                  KpiCard(
                    title: 'Utang Aktif',
                    value: AppFormatters.currency(
                      state.activeDebtByCustomer(customerId),
                    ),
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppTheme.warning,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Riwayat Transaksi'),
              const SizedBox(height: 10),
              if (transactions.isEmpty)
                const EmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: 'Belum ada transaksi',
                  subtitle: 'Transaksi pelanggan akan muncul di sini.',
                )
              else
                ...transactions.map(
                  (transaction) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(transaction.transactionCode),
                    subtitle: Text(
                      '${AppFormatters.dateTime(transaction.createdAt)} - ${transaction.paymentMethod.label}',
                    ),
                    trailing: Text(
                      AppFormatters.currency(transaction.totalAmount),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Riwayat Bon'),
              const SizedBox(height: 10),
              if (debts.isEmpty)
                const EmptyState(
                  icon: Icons.credit_score_rounded,
                  title: 'Tidak ada bon',
                  subtitle:
                      'Data bon pelanggan akan muncul jika pernah transaksi BON.',
                )
              else
                ...debts.map(
                  (debt) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppFormatters.currency(debt.originalAmount)),
                    subtitle: Text(
                      '${debt.status.label} - ${AppFormatters.date(debt.createdAt)}',
                    ),
                    trailing: Text(
                      AppFormatters.currency(debt.remainingAmount),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Riwayat Pembayaran Bon'),
              const SizedBox(height: 10),
              if (payments.isEmpty)
                const EmptyState(
                  icon: Icons.payments_outlined,
                  title: 'Belum ada pembayaran',
                  subtitle:
                      'Cicilan dan pelunasan bon pelanggan akan tampil di sini.',
                )
              else
                ...payments.map(
                  (payment) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppFormatters.currency(payment.amount)),
                    subtitle: Text(
                      '${payment.paymentMethod.label} - ${AppFormatters.dateTime(payment.paidAt)}',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
