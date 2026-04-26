import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/models/app_models.dart';
import '../../shared/state/app_state.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/app_formatters.dart';
import '../../shared/widgets/common_widgets.dart';

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posStateProvider);
    final activeDebts = state.activeDebtsSorted;
    final urgent =
        activeDebts.where((item) => item.ageInDays > 14).length.toDouble();
    final medium = activeDebts
        .where((item) => item.ageInDays >= 4 && item.ageInDays <= 14)
        .length
        .toDouble();
    final fresh = activeDebts
        .where((item) => item.ageInDays >= 0 && item.ageInDays <= 3)
        .length
        .toDouble();

    return AppPageScrollView(
      children: [
        HeroPanel(
          badge: const StatusChip(
            label: 'Bon aktif',
            color: Colors.white,
            icon: Icons.wallet_rounded,
          ),
          title: 'Manajemen BON yang lebih mudah dipantau.',
          subtitle:
              'Lihat prioritas tagihan, usia bon, dan catat cicilan dari tampilan yang lebih ringkas.',
          bottom: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              StatusChip(
                label: '${activeDebts.length} bon aktif',
                color: Colors.white,
              ),
              StatusChip(
                label: AppFormatters.currency(state.activeDebtTotal),
                color: Colors.white,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.95,
          children: [
            KpiCard(
              title: 'Piutang Aktif',
              value: AppFormatters.currency(state.activeDebtTotal),
              icon: Icons.account_balance_wallet_rounded,
              color: AppTheme.warning,
            ),
            KpiCard(
              title: 'Bon Aktif',
              value: '${activeDebts.length}',
              icon: Icons.pending_actions_rounded,
              color: AppTheme.deepTeal,
            ),
            KpiCard(
              title: 'Perlu Ditagih',
              value:
                  '${activeDebts.where((item) => item.ageInDays > 14).length}',
              icon: Icons.notification_important_rounded,
              color: AppTheme.danger,
            ),
            KpiCard(
              title: 'Cicilan',
              value: '${state.payments.length}',
              icon: Icons.payments_rounded,
              color: AppTheme.success,
            ),
          ],
        ),
        const SizedBox(height: 20),
        ChartCard(
          title: 'Distribusi Usia Bon',
          subtitle:
              'Semakin lama usia bon, semakin tinggi prioritas follow-up.',
          child: Column(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 42,
                    sections: [
                      PieChartSectionData(
                        value: urgent == 0 ? 1 : urgent,
                        color: AppTheme.danger,
                        title: urgent.toStringAsFixed(0),
                        radius: 58,
                      ),
                      PieChartSectionData(
                        value: medium == 0 ? 1 : medium,
                        color: AppTheme.warning,
                        title: medium.toStringAsFixed(0),
                        radius: 58,
                      ),
                      PieChartSectionData(
                        value: fresh == 0 ? 1 : fresh,
                        color: AppTheme.success,
                        title: fresh.toStringAsFixed(0),
                        radius: 58,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _LegendItem(color: AppTheme.danger, label: '> 14 hari'),
                  _LegendItem(color: AppTheme.warning, label: '4 - 14 hari'),
                  _LegendItem(color: AppTheme.success, label: '0 - 3 hari'),
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
              const SectionHeader(
                title: 'Daftar Bon Aktif',
                subtitle: 'Diurutkan dari usia utang paling lama.',
              ),
              const SizedBox(height: 12),
              if (activeDebts.isEmpty)
                const EmptyState(
                  icon: Icons.verified_user_rounded,
                  title: 'Tidak ada bon aktif',
                  subtitle: 'Semua pelanggan sudah lunas.',
                )
              else
                ...activeDebts.map(
                  (debt) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppSectionCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      debt.customerName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 6),
                                    DebtAgeIndicator(ageInDays: debt.ageInDays),
                                  ],
                                ),
                              ),
                              StatusChip(
                                label: debt.status.label,
                                color: debt.status == DebtStatus.partial
                                    ? AppTheme.warning
                                    : AppTheme.danger,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SummaryRow(
                            label: 'Utang awal',
                            value: AppFormatters.currency(debt.originalAmount),
                          ),
                          SummaryRow(
                            label: 'Sisa utang',
                            value: AppFormatters.currency(debt.remainingAmount),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () =>
                                    showDebtPaymentSheet(context, ref, debt),
                                icon: const Icon(Icons.payments_outlined),
                                label: const Text('Bayar Cicilan'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  await ref
                                      .read(posStateProvider)
                                      .markDebtPaid(debt.id);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Bon ${debt.customerName} ditandai lunas.',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.done_all_rounded),
                                label: const Text('Tandai Lunas'),
                              ),
                              FilledButton.icon(
                                onPressed: () =>
                                    context.go('/debts/${debt.id}'),
                                icon: const Icon(Icons.open_in_new_rounded),
                                label: const Text('Detail'),
                              ),
                            ],
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

Future<void> showDebtPaymentSheet(
  BuildContext context,
  WidgetRef ref,
  DebtRecord debt,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _DebtPaymentSheet(ref: ref, debt: debt),
  );
}

class _DebtPaymentSheet extends ConsumerStatefulWidget {
  const _DebtPaymentSheet({required this.ref, required this.debt});

  final WidgetRef ref;
  final DebtRecord debt;

  @override
  ConsumerState<_DebtPaymentSheet> createState() => _DebtPaymentSheetState();
}

class _DebtPaymentSheetState extends ConsumerState<_DebtPaymentSheet> {
  late final TextEditingController _controller;
  PaymentMethod _method = PaymentMethod.cash;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.debt.remainingAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetContainer(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bayar Bon ${widget.debt.customerName}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Sisa saat ini ${AppFormatters.currency(widget.debt.remainingAmount)}',
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('debt-payment-amount'),
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Nominal pembayaran'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in const [
                  PaymentMethod.cash,
                  PaymentMethod.qris,
                  PaymentMethod.transfer,
                ])
                  ChoiceChip(
                    label: Text(item.label),
                    selected: _method == item,
                    onSelected: (_) => setState(() => _method = item),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                try {
                  await widget.ref.read(posStateProvider).recordDebtPayment(
                        debtId: widget.debt.id,
                        amount: double.tryParse(_controller.text) ?? 0,
                        paymentMethod: _method,
                      );
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        error.toString().replaceFirst('Exception: ', ''),
                      ),
                    ),
                  );
                }
              },
              child: const Text('Simpan Pembayaran'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
