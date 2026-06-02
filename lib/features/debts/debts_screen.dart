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
    final activeDebtTotal = state.activeDebtTotal;
    final partialDebts =
        activeDebts.where((item) => item.status == DebtStatus.partial).length;

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
        _DebtSummaryPanel(
          activeDebtTotal: activeDebtTotal,
          activeDebtCount: activeDebts.length,
          urgentCount: urgent.toInt(),
          partialCount: partialDebts,
        ),
        const SizedBox(height: 14),
        _DebtAgeDistributionCard(
          urgent: urgent,
          medium: medium,
          fresh: fresh,
        ),
        const SizedBox(height: 20),
        _ActiveDebtListSection(
          debts: activeDebts,
          onPayDebt: (debt) => showDebtPaymentSheet(context, ref, debt),
          onMarkPaid: (debt) async {
            await ref.read(posStateProvider).markDebtPaid(debt.id);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Bon ${debt.customerName} ditandai lunas.'),
              ),
            );
          },
          onOpenDetail: (debt) => context.go('/debts/${debt.id}'),
        ),
      ],
    );
  }
}

class _DebtSummaryPanel extends StatelessWidget {
  const _DebtSummaryPanel({
    required this.activeDebtTotal,
    required this.activeDebtCount,
    required this.urgentCount,
    required this.partialCount,
  });

  final double activeDebtTotal;
  final int activeDebtCount;
  final int urgentCount;
  final int partialCount;

  @override
  Widget build(BuildContext context) {
    final urgentTone = urgentCount > 0 ? AppTheme.danger : AppTheme.success;

    return AppSectionCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Ringkasan Bon',
            subtitle:
                'Pantau nominal, prioritas, dan progres tagihan hari ini.',
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.deepTeal.withValues(alpha: 0.96),
                  AppTheme.teal.withValues(alpha: 0.90),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.deepTeal.withValues(alpha: 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const AppIcon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total piutang aktif',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.76),
                            ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppFormatters.currency(activeDebtTotal),
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontSize: 22,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DebtInsightPill(
                  icon: Icons.pending_actions_rounded,
                  label: '$activeDebtCount bon aktif',
                  color: AppTheme.deepTeal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DebtInsightPill(
                  icon: urgentCount > 0
                      ? Icons.priority_high_rounded
                      : Icons.check_circle_rounded,
                  label: urgentCount > 0 ? '$urgentCount follow-up' : 'Aman',
                  color: urgentTone,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DebtInsightPill(
                  icon: Icons.payments_rounded,
                  label: '$partialCount dicicil',
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DebtInsightPill extends StatelessWidget {
  const _DebtInsightPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, color: color, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtAgeDistributionCard extends StatelessWidget {
  const _DebtAgeDistributionCard({
    required this.urgent,
    required this.medium,
    required this.fresh,
  });

  final double urgent;
  final double medium;
  final double fresh;

  double get total => urgent + medium + fresh;

  @override
  Widget build(BuildContext context) {
    final hasData = total > 0;

    return AppSectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Distribusi Usia Bon',
            subtitle: 'Prioritaskan penagihan dari usia bon paling lama.',
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final useWideLayout = constraints.maxWidth >= 520;
              final chart = SizedBox(
                width: useWideLayout ? 176 : double.infinity,
                height: useWideLayout ? 176 : 184,
                child: hasData
                    ? Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.cloud.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: AppTheme.deepTeal.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                sectionsSpace: 4,
                                centerSpaceRadius: 46,
                                sections: [
                                  _ageSection(
                                    value: urgent,
                                    color: AppTheme.danger,
                                  ),
                                  _ageSection(
                                    value: medium,
                                    color: AppTheme.warning,
                                  ),
                                  _ageSection(
                                    value: fresh,
                                    color: AppTheme.success,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  total.toInt().toString(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(color: AppTheme.deepTeal),
                                ),
                                Text(
                                  'bon',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : const _EmptyDebtAgeChart(),
              );
              final legend = Column(
                children: [
                  _AgeBucketTile(
                    color: AppTheme.danger,
                    title: '> 14 hari',
                    subtitle: 'Perlu follow-up',
                    count: urgent.toInt(),
                  ),
                  const SizedBox(height: 8),
                  _AgeBucketTile(
                    color: AppTheme.warning,
                    title: '4 - 14 hari',
                    subtitle: 'Pantau berkala',
                    count: medium.toInt(),
                  ),
                  const SizedBox(height: 8),
                  _AgeBucketTile(
                    color: AppTheme.success,
                    title: '0 - 3 hari',
                    subtitle: 'Masih baru',
                    count: fresh.toInt(),
                  ),
                ],
              );

              if (useWideLayout) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    chart,
                    const SizedBox(width: 16),
                    Expanded(child: legend),
                  ],
                );
              }

              return Column(
                children: [
                  chart,
                  const SizedBox(height: 12),
                  legend,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  PieChartSectionData _ageSection({
    required double value,
    required Color color,
  }) {
    return PieChartSectionData(
      value: value <= 0 ? 0.01 : value,
      color: color,
      title: value <= 0 ? '' : value.toStringAsFixed(0),
      radius: 54,
      titleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _AgeBucketTile extends StatelessWidget {
  const _AgeBucketTile({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.count,
  });

  final Color color;
  final String title;
  final String subtitle;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$count',
            style: theme.textTheme.titleLarge?.copyWith(color: color),
          ),
          const SizedBox(width: 4),
          Text('bon', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _EmptyDebtAgeChart extends StatelessWidget {
  const _EmptyDebtAgeChart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 132,
        height: 132,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.foam,
          border: Border.all(color: AppTheme.deepTeal.withValues(alpha: 0.08)),
        ),
        child: const AppIcon(
          Icons.verified_user_rounded,
          color: AppTheme.deepTeal,
          size: 42,
        ),
      ),
    );
  }
}

class _ActiveDebtListSection extends StatelessWidget {
  const _ActiveDebtListSection({
    required this.debts,
    required this.onPayDebt,
    required this.onMarkPaid,
    required this.onOpenDetail,
  });

  final List<DebtRecord> debts;
  final ValueChanged<DebtRecord> onPayDebt;
  final ValueChanged<DebtRecord> onMarkPaid;
  final ValueChanged<DebtRecord> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Daftar Bon Aktif',
            subtitle: 'Diurutkan dari usia utang paling lama.',
          ),
          const SizedBox(height: 16),
          if (debts.isEmpty)
            const EmptyState(
              icon: Icons.verified_user_rounded,
              title: 'Tidak ada bon aktif',
              subtitle: 'Semua pelanggan sudah lunas.',
            )
          else
            for (final debt in debts) ...[
              _DebtListCard(
                debt: debt,
                onPayDebt: () => onPayDebt(debt),
                onMarkPaid: () => onMarkPaid(debt),
                onOpenDetail: () => onOpenDetail(debt),
              ),
              if (debt != debts.last) const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _DebtListCard extends StatelessWidget {
  const _DebtListCard({
    required this.debt,
    required this.onPayDebt,
    required this.onMarkPaid,
    required this.onOpenDetail,
  });

  final DebtRecord debt;
  final VoidCallback onPayDebt;
  final VoidCallback onMarkPaid;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor =
        debt.status == DebtStatus.partial ? AppTheme.warning : AppTheme.danger;
    final progress = debt.originalAmount <= 0
        ? 0.0
        : (debt.paidAmount / debt.originalAmount).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: statusColor.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.midnight.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0.78),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AppIcon(
                  Icons.person_search_rounded,
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.customerName,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Dibuat ${AppFormatters.date(debt.createdAt)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        DebtAgeIndicator(ageInDays: debt.ageInDays),
                        StatusChip(
                          label: debt.status.label,
                          color: statusColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Sisa', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 3),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 118),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        AppFormatters.currency(debt.remainingAmount),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.danger,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DebtAmountCaption(
                  label: 'Utang awal',
                  value: AppFormatters.currency(debt.originalAmount),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DebtAmountCaption(
                  label: 'Terbayar',
                  value: AppFormatters.currency(debt.paidAmount),
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onPayDebt,
                  icon: const AppIcon(Icons.payments_outlined),
                  label: const Text('Bayar Cicilan'),
                ),
              ),
              const SizedBox(width: 8),
              _DebtIconButton(
                onPressed: onMarkPaid,
                icon: const AppIcon(Icons.done_all_rounded),
                tooltip: 'Tandai lunas',
              ),
              const SizedBox(width: 8),
              _DebtIconButton(
                onPressed: onOpenDetail,
                icon: const AppIcon(Icons.open_in_new_rounded),
                tooltip: 'Buka detail',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DebtIconButton extends StatelessWidget {
  const _DebtIconButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  final VoidCallback onPressed;
  final Widget icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 50,
        height: 50,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            fixedSize: const Size(50, 50),
            minimumSize: const Size(50, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: icon,
        ),
      ),
    );
  }
}

class _DebtAmountCaption extends StatelessWidget {
  const _DebtAmountCaption({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final alignment =
        alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 3),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
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
