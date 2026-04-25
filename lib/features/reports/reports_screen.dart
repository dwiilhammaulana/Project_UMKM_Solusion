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
                'Preview laporan dibuat lebih rapi agar siap dikembangkan ke export PDF atau Excel.',
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
                title: 'Biaya',
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
          subtitle: 'Preview PDF · $dateLabel',
          action: FilledButton.icon(
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
                    child: Text('• $line'),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Bagian PDF final nantinya berisi tabel detail transaksi, biaya operasional, dan total bon belum lunas.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
