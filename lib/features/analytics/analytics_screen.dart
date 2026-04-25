import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/state/app_state.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/app_formatters.dart';
import '../../shared/widgets/common_widgets.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posStateProvider);
    final reports = state.reportSummaries;
    final costBuckets = <String, double>{};
    for (final item in state.operationalCosts) {
      costBuckets.update(
        item.costName,
        (value) => value + item.amount,
        ifAbsent: () => item.amount,
      );
    }

    const palette = [
      AppTheme.deepTeal,
      AppTheme.teal,
      AppTheme.success,
      AppTheme.info,
    ];

    return AppPageScrollView(
      children: [
        HeroPanel(
          badge: const StatusChip(
            label: 'Analitik',
            color: Colors.white,
            icon: Icons.insights_rounded,
          ),
          title: 'Baca performa usaha lewat grafik yang lebih ringan.',
          subtitle:
              'Visual analitik tetap mengambil data yang sama, tapi kini ditata lebih nyaman di layar mobile.',
        ),
        const SizedBox(height: 20),
        ChartCard(
          title: 'Pendapatan vs Modal vs Net Profit',
          subtitle: '6 bulan terakhir sesuai arah PRD.',
          child: BarChart(
            BarChartData(
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= reports.length) {
                        return const SizedBox.shrink();
                      }
                      return Text(reports[index].label);
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < reports.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: reports[i].revenue / 1000000,
                        color: AppTheme.deepTeal,
                        width: 8,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      BarChartRodData(
                        toY: reports[i].cost / 1000000,
                        color: AppTheme.info,
                        width: 8,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      BarChartRodData(
                        toY: reports[i].netProfit / 1000000,
                        color: AppTheme.success,
                        width: 8,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        ChartCard(
          title: 'Komposisi Biaya Operasional',
          subtitle: 'Distribusi biaya bulanan utama.',
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 36,
                    sectionsSpace: 2,
                    sections: [
                      for (final entry in costBuckets.entries.toList().asMap().entries)
                        PieChartSectionData(
                          value: entry.value.value,
                          title: '',
                          color: palette[entry.key % palette.length],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final entry in costBuckets.entries.toList().asMap().entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: palette[entry.key % palette.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(entry.value.key)),
                              Text(AppFormatters.currency(entry.value.value)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ChartCard(
          title: 'Tren Net Profit',
          subtitle: 'Line chart 6 bulan untuk memudahkan baca arah usaha.',
          child: LineChart(
            LineChartData(
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= reports.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(reports[index].label),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  color: AppTheme.success,
                  barWidth: 4,
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.success.withValues(alpha: 0.12),
                  ),
                  spots: [
                    for (var i = 0; i < reports.length; i++)
                      FlSpot(i.toDouble(), reports[i].netProfit / 1000000),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
