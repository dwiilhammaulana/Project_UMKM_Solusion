import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
    final storeName = state.appProfile.storeName;

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
            bottom: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                StatusChip(
                  label: 'Periode ${current.label}',
                  color: Colors.white,
                  icon: Icons.calendar_month_rounded,
                ),
                StatusChip(
                  label: '${state.todayTransactionCount} transaksi hari ini',
                  color: Colors.white,
                  icon: Icons.receipt_long_rounded,
                ),
                StatusChip(
                  label: 'Bon ${AppFormatters.currency(state.activeDebtTotal)}',
                  color: Colors.white,
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _ReportSnapshotPanel(
            current: current,
            activeDebtTotal: state.activeDebtTotal,
            reportSummaries: state.reportSummaries,
          ),
          const SizedBox(height: 20),
          AppSectionCard(
            child: _ProfitBreakdownPanel(current: current),
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
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.warning.withValues(alpha: 0.14),
                        AppTheme.foam.withValues(alpha: 0.72),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.deepTeal.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.payments_rounded,
                          color: AppTheme.warning,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              monthLabel,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${monthlyCosts.length} catatan biaya',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          AppFormatters.currency(monthlyCostTotal),
                          textAlign: TextAlign.end,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppTheme.midnight,
                                  ),
                        ),
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
                        storeName: storeName,
                        highlights: [
                          'Total transaksi: ${state.todayTransactionCount}',
                          'Pendapatan masuk hari ini: ${AppFormatters.currency(state.totalRevenue)}',
                          'Bon aktif: ${AppFormatters.currency(state.activeDebtTotal)}',
                        ],
                        onExport: () => _exportReportPdf(
                          title: 'Laporan Harian',
                          dateLabel: AppFormatters.date(DateTime.now()),
                          storeName: storeName,
                          rows: [
                            _ReportPdfRow(
                              label: 'Total transaksi',
                              value: '${state.todayTransactionCount}',
                            ),
                            _ReportPdfRow(
                              label: 'Pendapatan masuk hari ini',
                              value: AppFormatters.currency(state.totalRevenue),
                            ),
                            _ReportPdfRow(
                              label: 'Bon aktif',
                              value: AppFormatters.currency(
                                state.activeDebtTotal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _ReportPreviewCard(
                        title: 'Laporan Bulanan',
                        dateLabel: 'Bulan berjalan',
                        storeName: storeName,
                        highlights: [
                          'Pendapatan: ${AppFormatters.currency(current.revenue)}',
                          'Modal produk: ${AppFormatters.currency(current.cost)}',
                          'Biaya toko: ${AppFormatters.currency(current.operationalCost)}',
                          'Net profit: ${AppFormatters.currency(current.netProfit)}',
                        ],
                        onExport: () => _exportReportPdf(
                          title: 'Laporan Bulanan',
                          dateLabel: current.label,
                          storeName: storeName,
                          rows: [
                            _ReportPdfRow(
                              label: 'Pendapatan',
                              value: AppFormatters.currency(current.revenue),
                            ),
                            _ReportPdfRow(
                              label: 'Modal produk',
                              value: AppFormatters.currency(current.cost),
                            ),
                            _ReportPdfRow(
                              label: 'Biaya toko',
                              value: AppFormatters.currency(
                                current.operationalCost,
                              ),
                            ),
                            _ReportPdfRow(
                              label: 'Net profit',
                              value: AppFormatters.currency(current.netProfit),
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                      _ReportPreviewCard(
                        title: 'Laporan Tahunan',
                        dateLabel: '6 bulan terakhir',
                        storeName: storeName,
                        highlights: [
                          'Rekap pendapatan: ${AppFormatters.currency(state.reportSummaries.fold(0, (sum, item) => sum + item.revenue))}',
                          'Rekap biaya operasional: ${AppFormatters.currency(state.reportSummaries.fold(0, (sum, item) => sum + item.operationalCost))}',
                          'Piutang aktif per akhir periode: ${AppFormatters.currency(state.activeDebtTotal)}',
                        ],
                        onExport: () => _exportReportPdf(
                          title: 'Laporan Tahunan',
                          dateLabel: '6 bulan terakhir',
                          storeName: storeName,
                          rows: [
                            _ReportPdfRow(
                              label: 'Rekap pendapatan',
                              value: AppFormatters.currency(
                                state.reportSummaries.fold<double>(
                                  0,
                                  (sum, item) => sum + item.revenue,
                                ),
                              ),
                            ),
                            _ReportPdfRow(
                              label: 'Rekap modal produk',
                              value: AppFormatters.currency(
                                state.reportSummaries.fold<double>(
                                  0,
                                  (sum, item) => sum + item.cost,
                                ),
                              ),
                            ),
                            _ReportPdfRow(
                              label: 'Rekap biaya operasional',
                              value: AppFormatters.currency(
                                state.reportSummaries.fold<double>(
                                  0,
                                  (sum, item) => sum + item.operationalCost,
                                ),
                              ),
                            ),
                            _ReportPdfRow(
                              label: 'Rekap net profit',
                              value: AppFormatters.currency(
                                state.reportSummaries.fold<double>(
                                  0,
                                  (sum, item) => sum + item.netProfit,
                                ),
                              ),
                              isTotal: true,
                            ),
                            _ReportPdfRow(
                              label: 'Piutang aktif per akhir periode',
                              value: AppFormatters.currency(
                                state.activeDebtTotal,
                              ),
                            ),
                          ],
                          monthlySummaries: state.reportSummaries,
                        ),
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

  Future<void> _exportReportPdf({
    required String title,
    required String dateLabel,
    required String storeName,
    required List<_ReportPdfRow> rows,
    List<ReportSummary> monthlySummaries = const [],
  }) async {
    final generatedAt = DateTime.now();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            pw.Text(
              storeName,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Periode: $dateLabel'),
            pw.Text(
              'Dicetak: ${AppFormatters.dateTime(generatedAt)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 18),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: const {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(1.4),
              },
              children: [
                _buildPdfTableRow(
                  label: 'Komponen',
                  value: 'Nilai',
                  isHeader: true,
                ),
                ...rows.map(
                  (row) => _buildPdfTableRow(
                    label: row.label,
                    value: row.value,
                    isTotal: row.isTotal,
                  ),
                ),
              ],
            ),
            if (monthlySummaries.isNotEmpty) ...[
              pw.SizedBox(height: 22),
              pw.Text(
                'Rincian Bulanan',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  _buildMonthlyPdfRow(
                    'Bulan',
                    'Pendapatan',
                    'Modal',
                    'Biaya',
                    'Net Profit',
                    isHeader: true,
                  ),
                  ...monthlySummaries.map(
                    (summary) => _buildMonthlyPdfRow(
                      summary.label,
                      AppFormatters.currency(summary.revenue),
                      AppFormatters.currency(summary.cost),
                      AppFormatters.currency(summary.operationalCost),
                      AppFormatters.currency(summary.netProfit),
                    ),
                  ),
                ],
              ),
            ],
            pw.SizedBox(height: 18),
            pw.Text(
              'Detail transaksi dapat dilihat dari menu Kasir > Riwayat.',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.TableRow _buildPdfTableRow({
    required String label,
    required String value,
    bool isHeader = false,
    bool isTotal = false,
  }) {
    final style = pw.TextStyle(
      fontWeight: isHeader || isTotal ? pw.FontWeight.bold : null,
    );
    final backgroundColor = isHeader
        ? PdfColors.grey200
        : isTotal
            ? PdfColors.green50
            : PdfColors.white;

    return pw.TableRow(
      decoration: pw.BoxDecoration(color: backgroundColor),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label, style: style),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value, style: style),
        ),
      ],
    );
  }

  pw.TableRow _buildMonthlyPdfRow(
    String month,
    String revenue,
    String cost,
    String operationalCost,
    String netProfit, {
    bool isHeader = false,
  }) {
    final style = pw.TextStyle(
      fontSize: 9,
      fontWeight: isHeader ? pw.FontWeight.bold : null,
    );

    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: isHeader ? PdfColors.grey200 : PdfColors.white,
      ),
      children: [
        for (final value in [
          month,
          revenue,
          cost,
          operationalCost,
          netProfit,
        ])
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(value, style: style),
          ),
      ],
    );
  }
}

class _ReportPdfRow {
  const _ReportPdfRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;
}

class _ReportSnapshotPanel extends StatelessWidget {
  const _ReportSnapshotPanel({
    required this.current,
    required this.activeDebtTotal,
    required this.reportSummaries,
  });

  final ReportSummary current;
  final double activeDebtTotal;
  final List<ReportSummary> reportSummaries;

  @override
  Widget build(BuildContext context) {
    final margin = current.revenue <= 0
        ? 0.0
        : (current.netProfit / current.revenue) * 100;

    return AppSectionCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Ikhtisar Performa',
            subtitle:
                'Gambaran bulan berjalan tanpa ruang kosong di antara metrik utama.',
            action: StatusChip(
              label: current.label,
              color: AppTheme.deepTeal,
              icon: Icons.insights_rounded,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.midnight, AppTheme.deepTeal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.midnight.withValues(alpha: 0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.trending_up_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Net Profit',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppFormatters.currency(current.netProfit),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _SoftMetricBadge(
                      label: '${margin.toStringAsFixed(1)}%',
                      color: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _ReportTrendBars(summaries: reportSummaries),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _MetricTileGrid(
            children: [
              _MetricTile(
                title: 'Pendapatan',
                value: AppFormatters.currency(current.revenue),
                icon: Icons.bar_chart_rounded,
                color: AppTheme.success,
              ),
              _MetricTile(
                title: 'Modal Produk',
                value: AppFormatters.currency(current.cost),
                icon: Icons.inventory_2_rounded,
                color: AppTheme.info,
              ),
              _MetricTile(
                title: 'Biaya Toko',
                value: AppFormatters.currency(current.operationalCost),
                icon: Icons.receipt_rounded,
                color: AppTheme.warning,
              ),
              _MetricTile(
                title: 'Bon Aktif',
                value: AppFormatters.currency(activeDebtTotal),
                icon: Icons.account_balance_wallet_rounded,
                color: AppTheme.deepTeal,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTileGrid extends StatelessWidget {
  const _MetricTileGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 560;
        final columns = isWide ? 4 : 2;
        final spacing = 10.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTrendBars extends StatelessWidget {
  const _ReportTrendBars({required this.summaries});

  final List<ReportSummary> summaries;

  @override
  Widget build(BuildContext context) {
    var maxProfit = 1.0;
    for (final summary in summaries) {
      final value = summary.netProfit.abs();
      if (value > maxProfit) {
        maxProfit = value;
      }
    }

    return SizedBox(
      height: 74,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final summary in summaries) ...[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: (summary.netProfit.abs() / maxProfit)
                            .clamp(0.12, 1),
                        child: Container(
                          width: 14,
                          decoration: BoxDecoration(
                            color: summary.netProfit >= 0
                                ? AppTheme.mint
                                : AppTheme.danger,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                  ),
                ],
              ),
            ),
            if (summary != summaries.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _ProfitBreakdownPanel extends StatelessWidget {
  const _ProfitBreakdownPanel({required this.current});

  final ReportSummary current;

  @override
  Widget build(BuildContext context) {
    final margin = current.revenue <= 0
        ? 0.0
        : (current.netProfit / current.revenue) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Komponen Net Profit',
          subtitle:
              'Alur pendapatan sampai laba bersih dibuat lebih ringkas untuk dicek cepat.',
          action: _SoftMetricBadge(
            label: '${margin.toStringAsFixed(1)}% margin',
            color: AppTheme.success,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.foam.withValues(alpha: 0.68),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.deepTeal.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            children: [
              _ProfitLineRow(
                icon: Icons.add_rounded,
                label: 'Pendapatan',
                value: AppFormatters.currency(current.revenue),
                color: AppTheme.success,
              ),
              _ProfitLineRow(
                icon: Icons.remove_rounded,
                label: 'Modal produk terjual',
                value: AppFormatters.currency(current.cost),
                color: AppTheme.info,
              ),
              _ProfitLineRow(
                icon: Icons.remove_rounded,
                label: 'Biaya operasional toko',
                value: AppFormatters.currency(current.operationalCost),
                color: AppTheme.warning,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  height: 1,
                  color: AppTheme.deepTeal.withValues(alpha: 0.12),
                ),
              ),
              _ProfitLineRow(
                icon: Icons.done_rounded,
                label: 'Net profit',
                value: AppFormatters.currency(current.netProfit),
                color: current.netProfit >= 0
                    ? AppTheme.deepTeal
                    : AppTheme.danger,
                emphasized: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfitLineRow extends StatelessWidget {
  const _ProfitLineRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: emphasized
                  ? Theme.of(context).textTheme.titleMedium
                  : Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: emphasized ? color : AppTheme.ink,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftMetricBadge extends StatelessWidget {
  const _SoftMetricBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textColor = color == Colors.white ? Colors.white : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: color == Colors.white ? 0.14 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w800,
            ),
      ),
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
    required this.storeName,
    required this.highlights,
    required this.onExport,
  });

  final String title;
  final String dateLabel;
  final String storeName;
  final List<String> highlights;
  final VoidCallback onExport;

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
              onPressed: onExport,
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
              gradient: LinearGradient(
                colors: [
                  AppTheme.foam.withValues(alpha: 0.82),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.deepTeal.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppTheme.deepTeal.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.storefront_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            dateLabel,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.picture_as_pdf_rounded),
                  ],
                ),
                const SizedBox(height: 16),
                ...highlights.map(
                  (line) => _PreviewHighlightRow(text: line),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTheme.deepTeal.withValues(alpha: 0.07),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.history_rounded, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Detail transaksi tetap di Kasir > Riwayat.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewHighlightRow extends StatelessWidget {
  const _PreviewHighlightRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppTheme.deepTeal.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check_rounded, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.ink,
                  ),
            ),
          ),
        ],
      ),
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
