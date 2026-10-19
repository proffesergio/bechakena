import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../settings/ui/business_settings_status.dart';
import '../../../../app/providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/db/database.dart';
import '../../../../core/format.dart';
import '../../../../core/money.dart';
import 'chart_style.dart';

/// Single-series daily sales bars: thin marks, rounded data-ends, recessive
/// horizontal grid, tooltip on touch. Single series → no legend (title names it).
class SalesTrendChart extends ConsumerWidget {
  const SalesTrendChart(
      {super.key, required this.days, required this.rangeDays});

  final List<DailyTotal> days;
  final int rangeDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsStatus = businessSettingsStatus(ref, context);
    if (settingsStatus != null) return settingsStatus;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final series = seriesColor(context);
    final byDay = {for (final d in days) d.day: d};

    // Fill missing days with zero so the axis is continuous.
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final slots = [
      for (var i = rangeDays - 1; i >= 0; i--)
        today.subtract(Duration(days: i)),
    ];
    String keyOf(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final maxPaisa = days.fold<int>(
        0, (m, d) => d.total.paisa > m ? d.total.paisa : m);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxPaisa == 0 ? 100 : maxPaisa * 1.15) / 100,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (value, meta) => Text(
                value == 0 ? '0' : '${ref.watch(shopCurrencyProvider).symbol}${compactTaka(value)}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= slots.length) return const SizedBox();
                if (rangeDays == 30 && i % 5 != 0) return const SizedBox();
                final d = slots[i];
                final label = '${d.day}/${d.month}';
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    locale == 'bn' ? toBanglaDigits(label) : label,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => theme.colorScheme.inverseSurface,
            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
              formatTaka(Money((rod.toY * 100).round()), locale: locale, currency: ref.read(shopCurrencyProvider)),
              TextStyle(color: theme.colorScheme.onInverseSurface),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < slots.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (byDay[keyOf(slots[i])]?.total.paisa ?? 0) / 100,
                  color: series,
                  width: rangeDays == 30 ? 7 : 16,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
