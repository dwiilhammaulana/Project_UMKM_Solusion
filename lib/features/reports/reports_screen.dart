import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../shared/models/app_models.dart';
import '../../shared/state/app_state.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/app_formatters.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/operational_cost_form_sheet.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late DateTime _selectedOperationalMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedOperationalMonth = DateTime(now.year, now.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(posStateProvider);
    final current = state.reportSummaries.last;
    final monthlyCosts =
        state.operationalCostsByMonth(_selectedOperationalMonth);
    final monthlyCostTotal =
        state.operationalCostTotalByMonth(_selectedOperationalMonth);
    final monthLabel = DateFormat(
      'MMMM yyyy',
      'id_ID',
    ).format(_selectedOperationalMonth);

    return DefaultTabController(
      length: 3,
      child: AppPageScrollView(
        children: [
          HeroPanel(
            badge: const StatusChip(
              label: 'Laporan',
              color: Colors.white,
              icon: Icons.description_rounded,
            ),
            title: 'Ringkasan bisnis yang lebih enak dibaca.',
            subtitle:
                'Pendapatan, modal produk, dan biaya operasional toko kini bisa disetel agar net profit lebih akurat.',
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.0,
            children: [
              KpiCard(
                title: 'Pendapatan',
                value: AppFormatters.currency(current.revenue),
                icon: Icons.bar_chart_rounded,
                color: AppTheme.success,
              ),
              KpiCard(
                title: 'Modal Produk',
                value: AppFormatters.currency(current.cost),
                icon: Icons.inventory_2_rounded,
                color: AppTheme.info,
                subtitle: 'Akumulasi harga modal produk terjual',
              ),
              KpiCard(
                title: 'Biaya Toko',
                value: AppFormatters.currency(current.operationalCost),
                icon: Icons.receipt_rounded,
                color: AppTheme.warning,
                subtitle: 'Biaya operasional bulan berjalan',
              ),
              KpiCard(
                title: 'Net Profit',
                value: AppFormatters.currency(current.netProfit),
                icon: Icons.show_chart_rounded,
                color: AppTheme.info,
                subtitle: 'Pendapatan - modal - biaya toko',
              ),
              KpiCard(
                title: 'Bon Aktif',
                value: AppFormatters.currency(state.activeDebtTotal),
                icon: Icons.account_balance_wallet_rounded,
                color: AppTheme.deepTeal,
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Komponen Net Profit',
                  subtitle:
                      'Ringkasan cepat agar langsung terlihat kenapa nilai profit terbentuk.',
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.foam,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SummaryRow(
                        label: 'Pendapatan',
                        value: AppFormatters.currency(current.revenue),
                      ),
                      SummaryRow(
                        label: 'Modal produk terjual',
                        value: '- ${AppFormatters.currency(current.cost)}',
                      ),
                      SummaryRow(
                        label: 'Biaya operasional toko',
                        value:
                            '- ${AppFormatters.currency(current.operationalCost)}',
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Divider(
                          height: 1,
                          color: AppTheme.deepTeal.withValues(alpha: 0.12),
                        ),
                      ),
                      SummaryRow(
                        label: 'Net profit',
                        value: AppFormatters.currency(current.netProfit),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rumus: Pendapatan - Modal Produk - Biaya Toko',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Biaya Operasional Bulanan',
                  subtitle:
                      'Input biaya toko manual agar cost dan net profit sesuai kondisi warung.',
                  action: _CompactHeaderButton(
                    child: FilledButton.icon(
                      key: const Key('reports-add-operational-cost'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onPressed: () => showOperationalCostFormSheet(
                        context,
                        ref,
                        initialMonth: _selectedOperationalMonth,
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Tambah'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(6, (index) {
                    final month = DateTime(
                      DateTime.now().year,
                      DateTime.now().month - index,
                      1,
                    );
                    final isSelected =
                        month.year == _selectedOperationalMonth.year &&
                            month.month == _selectedOperationalMonth.month;
                    return AppFilterChip(
                      label: DateFormat('MMM yyyy', 'id_ID').format(month),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedOperationalMonth = month;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.foam,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monthLabel,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SummaryRow(
                        label: 'Total biaya bulan ini',
                        value: AppFormatters.currency(monthlyCostTotal),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (monthlyCosts.isEmpty)
                  const EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'Belum ada biaya operasional',
                    subtitle:
                        'Tambahkan biaya seperti listrik, gaji, sewa, atau pengeluaran warung lainnya.',
                  )
                else
                  ...monthlyCosts.map(
                    (cost) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OperationalCostTile(
                        operationalCost: cost,
                        onEdit: () => showOperationalCostFormSheet(
                          context,
                          ref,
                          operationalCost: cost,
                        ),
                        onDelete: () => _confirmDeleteOperationalCost(cost),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppSectionCard(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.foam,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const TabBar(
                    tabs: [
                      Tab(text: 'Harian'),
                      Tab(text: 'Bulanan'),
                      Tab(text: 'Tahunan'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 420,
                  child: TabBarView(
                    children: [
                      _ReportPreviewCard(
                        title: 'Laporan Harian',
                        dateLabel: 'Hari ini',
                        highlights: [
                          'Total transaksi: ${state.todayTransactionCount}',
                          'Pendapatan masuk hari ini: ${AppFormatters.currency(state.totalRevenue)}',
                          'Bon aktif: ${AppFormatters.currency(state.activeDebtTotal)}',
                        ],
                      ),
                      _ReportPreviewCard(
                        title: 'Laporan Bulanan',
                        dateLabel: 'Bulan berjalan',
                        highlights: [
                          'Pendapatan: ${AppFormatters.currency(current.revenue)}',
                          'Modal produk: ${AppFormatters.currency(current.cost)}',
                          'Biaya toko: ${AppFormatters.currency(current.operationalCost)}',
                          'Net profit: ${AppFormatters.currency(current.netProfit)}',
                        ],
                      ),
                      _ReportPreviewCard(
                        title: 'Laporan Tahunan',
                        dateLabel: '6 bulan terakhir',
                        highlights: [
                          'Rekap pendapatan: ${AppFormatters.currency(state.reportSummaries.fold(0, (sum, item) => sum + item.revenue))}',
                          'Rekap biaya operasional: ${AppFormatters.currency(state.reportSummaries.fold(0, (sum, item) => sum + item.operationalCost))}',
                          'Piutang aktif per akhir periode: ${AppFormatters.currency(state.activeDebtTotal)}',
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteOperationalCost(OperationalCost cost) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus biaya operasional?'),
          content: Text(
            'Biaya ${cost.costName} untuk ${DateFormat('MMMM yyyy', 'id_ID').format(cost.monthYear)} akan dihapus.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    await ref.read(posStateProvider).deleteOperationalCost(cost.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${cost.costName} berhasil dihapus.')),
    );
  }
}

class _OperationalCostTile extends StatelessWidget {
  const _OperationalCostTile({
    required this.operationalCost,
    required this.onEdit,
    required this.onDelete,
  });

  final OperationalCost operationalCost;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.foam,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.receipt_rounded,
              color: AppTheme.deepTeal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  operationalCost.costName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat(
                    'MMMM yyyy',
                    'id_ID',
                  ).format(operationalCost.monthYear),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppFormatters.currency(operationalCost.amount),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppTheme.danger,
          ),
        ],
      ),
    );
  }
}

class _ReportPreviewCard extends StatelessWidget {
  const _ReportPreviewCard({
    required this.title,
    required this.dateLabel,
    required this.highlights,
  });

  final String title;
  final String dateLabel;
  final List<String> highlights;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          subtitle: 'Preview PDF - $dateLabel',
          action: _CompactHeaderButton(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Export PDF masih berupa placeholder UI.'),
                  ),
                );
              },
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('Export'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.foam, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Warung Kopi Pertigaan Jati',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...highlights.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text('- $line'),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Detail transaksi tetap diakses dari Kasir > Riwayat agar halaman laporan fokus ke ringkasan dan rekap periodik.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactHeaderButton extends StatelessWidget {
  const _CompactHeaderButton({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(child: child);
  }
}
