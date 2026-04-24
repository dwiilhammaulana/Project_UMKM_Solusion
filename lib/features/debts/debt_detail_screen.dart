import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/app_models.dart';
import '../../shared/state/app_state.dart';
import '../../shared/utils/app_formatters.dart';
import '../../shared/widgets/common_widgets.dart';
import 'debts_screen.dart';

class DebtDetailScreen extends ConsumerWidget {
  const DebtDetailScreen({super.key, required this.debtId});

  final String debtId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posStateProvider);
    final matches = state.debts.where((debt) => debt.id == debtId);
    if (matches.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_rounded,
        title: 'Data bon tidak ditemukan',
        subtitle: 'Kembali ke daftar bon dan pilih item lain.',
      );
    }

    final debt = matches.first;
    final payments = state.payments
        .where((item) => item.debtId == debtId)
        .toList()
      ..sort((a, b) => b.paidAt.compareTo(a.paidAt));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                debt.customerName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              DebtAgeIndicator(ageInDays: debt.ageInDays),
              const SizedBox(height: 12),
              SummaryRow(
                label: 'Utang awal',
                value: AppFormatters.currency(debt.originalAmount),
              ),
              SummaryRow(
                label: 'Sudah dibayar',
                value: AppFormatters.currency(debt.paidAmount),
              ),
              SummaryRow(
                label: 'Sisa',
                value: AppFormatters.currency(debt.remainingAmount),
              ),
              SummaryRow(
                label: 'Tanggal dibuat',
                value: AppFormatters.date(debt.createdAt),
              ),
              if (debt.dueDate != null)
                SummaryRow(
                  label: 'Jatuh tempo',
                  value: AppFormatters.date(debt.dueDate!),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => showDebtPaymentSheet(context, ref, debt),
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Bayar Cicilan'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await ref.read(posStateProvider).markDebtPaid(debt.id);
                      },
                      icon: const Icon(Icons.done_all_rounded),
                      label: const Text('Lunasi'),
                    ),
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
              const SectionHeader(title: 'Riwayat Pembayaran'),
              const SizedBox(height: 12),
              if (payments.isEmpty)
                const EmptyState(
                  icon: Icons.payments_outlined,
                  title: 'Belum ada cicilan',
                  subtitle:
                      'Pembayaran bon akan muncul di sini setelah dicatat.',
                )
              else
                ...payments.map(
                  (payment) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppFormatters.currency(payment.amount)),
                    subtitle: Text(
                      '${payment.paymentMethod.label} • ${AppFormatters.dateTime(payment.paidAt)}',
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
