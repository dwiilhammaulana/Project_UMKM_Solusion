import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/app_models.dart';
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
    final latest = reports.last;
    final totalRevenue = reports.fold<double>(
      0,
      (sum, item) => sum + item.revenue,
    );
    final totalCost = reports.fold<double>(
      0,
      (sum, item) => sum + item.cost + item.operationalCost,
    );
    final totalProfit = reports.fold<double>(
      0,
      (sum, item) => sum + item.netProfit,
    );
    final averageProfit = reports.isEmpty ? 0.0 : totalProfit / reports.length;
    final profitMargin = totalRevenue <= 0 ? 0.0 : totalProfit / totalRevenue;
    final bestMonth = reports.fold<ReportSummary>(
      latest,
      (best, item) => item.netProfit > best.netProfit ? item : best,
    );
    final costBuckets = _buildCostBuckets(state.operationalCosts);

    return AppPageScrollView(
      children: [
        HeroPanel(
          badge: const StatusChip(
            label: 'Analitik',
            color: Colors.white,
            icon: Icons.insights_rounded,
          ),
          title: 'Baca performa usaha lewat grafik yang lebih jelas.',
          subtitle:
              'Pendapatan, biaya, dan profit dibuat lebih terukur agar keputusan harian lebih mudah diambil.',
          bottom: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              StatusChip(
                label: 'Margin ${(profitMargin * 100).toStringAsFixed(1)}%',
                color: Colors.white,
                icon: Icons.percent_rounded,
              ),
              StatusChip(
                label: 'Bulan terbaik ${bestMonth.label}',
                color: Colors.white,
                icon: Icons.emoji_events_rounded,
              ),
              StatusChip(
                label: 'Rata-rata ${AppFormatters.currency(averageProfit)}',
                color: Colors.white,
                icon: Icons.show_chart_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _AnalyticsSummaryPanel(
          totalRevenue: totalRevenue,
          totalCost: totalCost,
          totalProfit: totalProfit,
          averageProfit: averageProfit,
        ),
        const SizedBox(height: 20),
        _ModernChartCard(
          title: 'Perbandingan Keuangan',
          subtitle:
              'Pendapatan, modal produk, biaya toko, dan net profit dalam juta rupiah.',
          footer: 'Net profit = pendapatan - modal produk - biaya toko.',
          legends: const [
            _ChartLegend(label: 'Pendapatan', color: AppTheme.deepTeal),
            _ChartLegend(label: 'Modal', color: AppTheme.info),
            _ChartLegend(label: 'Biaya', color: AppTheme.warning),
            _ChartLegend(label: 'Net Profit', color: AppTheme.success),
          ],
          child: _FinancialBarsChart(reports: reports),
        ),
        const SizedBox(height: 20),
        _ModernChartCard(
          title: 'Komposisi Biaya Operasional',
          subtitle:
              'Kategori biaya diurutkan dari nominal terbesar agar prioritas penghematan terlihat.',
          footer: costBuckets.isEmpty
              ? 'Belum ada biaya operasional yang tercatat.'
              : 'Total biaya: ${AppFormatters.currency(costBuckets.fold<double>(0, (sum, item) => sum + item.amount))}.',
          child: _CostBreakdownChart(costBuckets: costBuckets),
        ),
        const SizedBox(height: 20),
        _ModernChartCard(
          title: 'Tren Net Profit',
          subtitle:
              'Arah profit 6 bulan terakhir dengan garis referensi nol untuk membaca untung atau rugi.',
          footer:
              'Rata-rata profit: ${AppFormatters.currency(averageProfit)} per bulan.',
          legends: const [
            _ChartLegend(label: 'Net Profit', color: AppTheme.success),
            _ChartLegend(label: 'Area positif', color: AppTheme.mint),
          ],
          child: _ProfitTrendChart(reports: reports),
        ),
      ],
    );
  }
}

List<_CostBucket> _buildCostBuckets(List<OperationalCost> costs) {
  final buckets = <String, double>{};
  for (final item in costs) {
    buckets.update(
      item.costName,
      (value) => value + item.amount,
      ifAbsent: () => item.amount,
    );
  }

  final result = buckets.entries
      .map((entry) => _CostBucket(label: entry.key, amount: entry.value))
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));
  return result;
}

class _AnalyticsSummaryPanel extends StatelessWidget {
  const _AnalyticsSummaryPanel({
    required this.totalRevenue,
    required this.totalCost,
    required this.totalProfit,
    required this.averageProfit,
  });

  final double totalRevenue;
  final double totalCost;
  final double totalProfit;
  final double averageProfit;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Ringkasan 6 Bulan',
            subtitle:
                'Angka utama sebelum membaca diagram, supaya konteksnya tidak hilang.',
          ),
          const SizedBox(height: 16),
          _MetricGrid(
            children: [
              _AnalyticsMetricTile(
                title: 'Pendapatan',
                value: AppFormatters.currency(totalRevenue),
                icon: Icons.payments_rounded,
                color: AppTheme.deepTeal,
              ),
              _AnalyticsMetricTile(
                title: 'Total Biaya',
                value: AppFormatters.currency(totalCost),
                icon: Icons.receipt_long_rounded,
                color: AppTheme.warning,
              ),
              _AnalyticsMetricTile(
                title: 'Net Profit',
                value: AppFormatters.currency(totalProfit),
                icon: Icons.trending_up_rounded,
                color: totalProfit >= 0 ? AppTheme.success : AppTheme.danger,
              ),
              _AnalyticsMetricTile(
                title: 'Rata-rata',
                value: AppFormatters.currency(averageProfit),
                icon: Icons.stacked_line_chart_rounded,
                color: averageProfit >= 0 ? AppTheme.info : AppTheme.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModernChartCard extends StatelessWidget {
  const _ModernChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
    this.legends = const [],
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String? footer;
  final List<_ChartLegend> legends;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title, subtitle: subtitle),
          if (legends.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final legend in legends)
                  _LegendPill(label: legend.label, color: legend.color),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Container(
            height: 290,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 18, 12, 10),
            decoration: BoxDecoration(
              color: AppTheme.cloud.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.deepTeal.withValues(alpha: 0.07),
              ),
            ),
            child: child,
          ),
          if (footer != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    footer!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FinancialBarsChart extends StatelessWidget {
  const _FinancialBarsChart({required this.reports});

  final List<ReportSummary> reports;

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const _EmptyChartMessage(
        icon: Icons.bar_chart_rounded,
        title: 'Belum ada data laporan',
      );
    }

    final maxValue = _maxReportValue(reports);
    final minProfit = reports.fold<double>(
      0,
      (minValue, item) => math.min(minValue, item.netProfit),
    );
    final maxY = _roundedMillion(maxValue);
    final minY = minProfit < 0 ? -_roundedMillion(minProfit.abs()) : 0.0;

    return BarChart(
      BarChartData(
        minY: minY,
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 14,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final report = reports[group.x.toInt()];
              final label = switch (rodIndex) {
                0 => 'Pendapatan',
                1 => 'Modal',
                2 => 'Biaya',
                _ => 'Net Profit',
              };
              final rawValue = switch (rodIndex) {
                0 => report.revenue,
                1 => report.cost,
                2 => report.operationalCost,
                _ => report.netProfit,
              };
              return BarTooltipItem(
                '$label\n${AppFormatters.currency(rawValue)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              );
            },
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _chartInterval(maxY),
          getDrawingHorizontalLine: (value) => FlLine(
            color: value == 0
                ? AppTheme.deepTeal.withValues(alpha: 0.24)
                : AppTheme.deepTeal.withValues(alpha: 0.08),
            strokeWidth: value == 0 ? 1.2 : 1,
          ),
        ),
        titlesData: _bottomAndLeftTitles(
          context: context,
          reports: reports,
          interval: _chartInterval(maxY),
        ),
        barGroups: [
          for (var i = 0; i < reports.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 3,
              barRods: [
                _barRod(reports[i].revenue, AppTheme.deepTeal),
                _barRod(reports[i].cost, AppTheme.info),
                _barRod(reports[i].operationalCost, AppTheme.warning),
                _barRod(reports[i].netProfit, AppTheme.success),
              ],
            ),
        ],
      ),
    );
  }
}

class _CostBreakdownChart extends StatelessWidget {
  const _CostBreakdownChart({required this.costBuckets});

  final List<_CostBucket> costBuckets;

  static const _palette = [
    AppTheme.deepTeal,
    AppTheme.teal,
    AppTheme.success,
    AppTheme.info,
    AppTheme.warning,
    AppTheme.danger,
  ];

  @override
  Widget build(BuildContext context) {
    if (costBuckets.isEmpty) {
      return const _EmptyChartMessage(
        icon: Icons.pie_chart_outline_rounded,
        title: 'Belum ada biaya operasional',
      );
    }

    final total = costBuckets.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;
        final chart = PieChart(
          PieChartData(
            centerSpaceRadius: isCompact ? 42 : 54,
            sectionsSpace: 3,
            pieTouchData: PieTouchData(enabled: true),
            sections: [
              for (var i = 0; i < costBuckets.length; i++)
                PieChartSectionData(
                  value: costBuckets[i].amount,
                  radius: isCompact ? 52 : 66,
                  title: _percentageLabel(costBuckets[i].amount, total),
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                  color: _palette[i % _palette.length],
                ),
            ],
          ),
        );

        final legend = SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < costBuckets.length; i++)
                _CostLegendRow(
                  color: _palette[i % _palette.length],
                  bucket: costBuckets[i],
                  total: total,
                ),
            ],
          ),
        );

        if (isCompact) {
          return Column(
            children: [
              Expanded(child: chart),
              const SizedBox(height: 12),
              SizedBox(height: 92, child: legend),
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 5, child: chart),
            const SizedBox(width: 16),
            Expanded(flex: 6, child: legend),
          ],
        );
      },
    );
  }
}

class _ProfitTrendChart extends StatelessWidget {
  const _ProfitTrendChart({required this.reports});

  final List<ReportSummary> reports;

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const _EmptyChartMessage(
        icon: Icons.show_chart_rounded,
        title: 'Belum ada tren profit',
      );
    }

    final maxAbs = reports.fold<double>(
      1,
      (value, item) => math.max(value, item.netProfit.abs()),
    );
    final maxY = _roundedMillion(maxAbs);
    final minY = reports.any((item) => item.netProfit < 0) ? -maxY : 0.0;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 14,
            getTooltipItems: (spots) {
              return [
                for (final spot in spots)
                  LineTooltipItem(
                    '${reports[spot.x.toInt()].label}\n'
                    '${AppFormatters.currency(reports[spot.x.toInt()].netProfit)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
              ];
            },
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _chartInterval(maxY),
          getDrawingHorizontalLine: (value) => FlLine(
            color: value == 0
                ? AppTheme.deepTeal.withValues(alpha: 0.24)
                : AppTheme.deepTeal.withValues(alpha: 0.08),
            strokeWidth: value == 0 ? 1.2 : 1,
          ),
        ),
        titlesData: _bottomAndLeftTitles(
          context: context,
          reports: reports,
          interval: _chartInterval(maxY),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            preventCurveOverShooting: true,
            color: AppTheme.success,
            barWidth: 4,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 3,
                  strokeColor: reports[index].netProfit >= 0
                      ? AppTheme.success
                      : AppTheme.danger,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.mint.withValues(alpha: 0.24),
                  AppTheme.mint.withValues(alpha: 0.02),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            spots: [
              for (var i = 0; i < reports.length; i++)
                FlSpot(i.toDouble(), _toMillion(reports[i].netProfit)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 4 : 2;
        const spacing = 10.0;
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

class _AnalyticsMetricTile extends StatelessWidget {
  const _AnalyticsMetricTile({
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

class _LegendPill extends StatelessWidget {
  const _LegendPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _CostLegendRow extends StatelessWidget {
  const _CostLegendRow({
    required this.color,
    required this.bucket,
    required this.total,
  });

  final Color color;
  final _CostBucket bucket;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bucket.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  _percentageLabel(bucket.amount, total),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            AppFormatters.currency(bucket.amount),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _EmptyChartMessage extends StatelessWidget {
  const _EmptyChartMessage({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: AppTheme.deepTeal),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _ChartLegend {
  const _ChartLegend({required this.label, required this.color});

  final String label;
  final Color color;
}

class _CostBucket {
  const _CostBucket({required this.label, required this.amount});

  final String label;
  final double amount;
}

FlTitlesData _bottomAndLeftTitles({
  required BuildContext context,
  required List<ReportSummary> reports,
  required double interval,
}) {
  return FlTitlesData(
    rightTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    topTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 44,
        interval: interval,
        getTitlesWidget: (value, meta) {
          if (value == meta.max || value == meta.min) {
            return const SizedBox.shrink();
          }
          return Text(
            '${value.toStringAsFixed(value.abs() >= 10 ? 0 : 1)}jt',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                ),
          );
        },
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 32,
        getTitlesWidget: (value, meta) {
          final index = value.toInt();
          if (index < 0 || index >= reports.length || value != index) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              reports[index].label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                  ),
            ),
          );
        },
      ),
    ),
  );
}

BarChartRodData _barRod(double value, Color color) {
  return BarChartRodData(
    toY: _toMillion(value),
    color: value >= 0 ? color : AppTheme.danger,
    width: 7,
    borderRadius: BorderRadius.circular(999),
  );
}

double _maxReportValue(List<ReportSummary> reports) {
  return reports.fold<double>(1, (maxValue, item) {
    return [
      maxValue,
      item.revenue.abs(),
      item.cost.abs(),
      item.operationalCost.abs(),
      item.netProfit.abs(),
    ].reduce(math.max);
  });
}

double _roundedMillion(double rawValue) {
  final value = math.max(_toMillion(rawValue), 1);
  if (value <= 5) {
    return 5;
  }
  if (value <= 10) {
    return 10;
  }
  return (value / 5).ceil() * 5;
}

double _chartInterval(double maxY) {
  if (maxY <= 5) {
    return 1;
  }
  if (maxY <= 10) {
    return 2;
  }
  return (maxY / 4).ceilToDouble();
}

double _toMillion(double value) => value / 1000000;

String _percentageLabel(double value, double total) {
  if (total <= 0) {
    return '0%';
  }
  return '${((value / total) * 100).toStringAsFixed(1)}%';
}
