import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/state/app_state.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/app_formatters.dart';
import '../../shared/widgets/common_widgets.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posStateProvider);
    final current = state.reportSummaries.last;

    return DefaultTabController(
      length: 3,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(
            title: 'Laporan',
            subtitle:
                'Dummy preview laporan harian, bulanan, dan tahunan sebelum export PDF.',
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.15,
            children: [
              KpiCard(
                title: 'Pendapatan Bulan Ini',
                value: AppFormatters.currency(current.revenue),
                icon: Icons.bar_chart_rounded,
                color: AppTheme.success,
              ),
              KpiCard(
                title: 'Biaya Operasional',
                value: AppFormatters.currency(current.operationalCost),
                icon: Icons.receipt_rounded,
                color: AppTheme.warning,
              ),
              KpiCard(
                title: 'Net Profit',
                value: AppFormatters.currency(current.netProfit),
                icon: Icons.show_chart_rounded,
                color: AppTheme.info,
              ),
              KpiCard(
                title: 'Total Bon Aktif',
                value: AppFormatters.currency(state.activeDebtTotal),
                icon: Icons.account_balance_wallet_rounded,
                color: AppTheme.moss,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const TabBar(
            tabs: [
              Tab(text: 'Harian'),
              Tab(text: 'Bulanan'),
              Tab(text: 'Tahunan'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 560,
            child: TabBarView(
              children: [
                _ReportPreviewCard(
                  title: 'Laporan Harian',
                  dateLabel: '22 April 2026',
                  highlights: [
                    'Total transaksi: ${state.todayTransactionCount}',
                    'Pendapatan masuk hari ini: ${AppFormatters.currency(state.totalRevenue)}',
                    'Bon aktif: ${AppFormatters.currency(state.activeDebtTotal)}',
                  ],
                ),
                _ReportPreviewCard(
                  title: 'Laporan Bulanan',
                  dateLabel: 'April 2026',
                  highlights: [
                    'Pendapatan: ${AppFormatters.currency(current.revenue)}',
                    'Modal: ${AppFormatters.currency(current.cost)}',
                    'Total bon belum lunas: ${AppFormatters.currency(current.activeDebtTotal)}',
                  ],
                ),
                _ReportPreviewCard(
                  title: 'Laporan Tahunan',
                  dateLabel: '2026',
                  highlights: [
                    'Rekap 6 bulan terakhir: ${AppFormatters.currency(state.reportSummaries.fold(0, (sum, item) => sum + item.revenue))}',
                    'Biaya operasional: ${AppFormatters.currency(state.reportSummaries.fold(0, (sum, item) => sum + item.operationalCost))}',
                    'Piutang aktif per akhir periode: ${AppFormatters.currency(state.activeDebtTotal)}',
                  ],
                ),
              ],
            ),
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
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: title,
            subtitle: 'Preview PDF - $dateLabel',
            action: FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Export PDF masih berupa placeholder UI.'),
                  ),
                );
              },
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('Export PDF'),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.mist,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Warung Kopi Pertigaan Jati',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...highlights.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text('- $line'),
                  ),
                ),
                const Divider(height: 24),
                const Text(
                  'Bagian PDF final nantinya berisi tabel detail transaksi, biaya operasional, dan total bon belum lunas.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
