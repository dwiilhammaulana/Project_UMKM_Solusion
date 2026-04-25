import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/models/app_models.dart';
import '../../shared/state/app_state.dart';
import '../../shared/theme/app_theme.dart';
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

    return AppPageScrollView(
      children: [
        HeroPanel(
          badge: const StatusChip(
            label: 'Detail BON',
            color: Colors.white,
            icon: Icons.receipt_long_rounded,
          ),
          title: debt.customerName,
          subtitle:
              'Pantau sisa utang, jatuh tempo, dan histori pembayaran dalam satu layar.',
          trailing: IconButton.filled(
            onPressed: () => context.pop(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.deepTeal,
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          bottom: DebtAgeIndicator(ageInDays: debt.ageInDays),
        ),
        const SizedBox(height: 20),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    child: FilledButton.icon(
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
        const SizedBox(height: 20),
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
                  subtitle: 'Pembayaran bon akan muncul di sini setelah dicatat.',
                )
              else
                ...payments.map(
                  (payment) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.foam,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.payments_rounded,
                              color: AppTheme.deepTeal,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppFormatters.currency(payment.amount),
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${payment.paymentMethod.label} · ${AppFormatters.dateTime(payment.paidAt)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
