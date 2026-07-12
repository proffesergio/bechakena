import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../../../core/format.dart';
import '../../../core/money.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/logic/session.dart';

// Chart colors from the validated dataviz reference palette (light/dark are
// selected steps, not an automatic flip). Payment methods keep fixed entity
// colors: cash=blue, bKash=magenta, Nagad=orange, card=violet.
const _seriesLight = Color(0xFF2A78D6);
const _seriesDark = Color(0xFF3987E5);
const _payLight = {
  PayMethod.cash: Color(0xFF2A78D6),
  PayMethod.bkash: Color(0xFFE87BA4),
  PayMethod.nagad: Color(0xFFEB6834),
  PayMethod.card: Color(0xFF4A3AA7),
};
const _payDark = {
  PayMethod.cash: Color(0xFF3987E5),
  PayMethod.bkash: Color(0xFFD55181),
  PayMethod.nagad: Color(0xFFD95926),
  PayMethod.card: Color(0xFF9085E9),
};

class _RangeDays extends Notifier<int> {
  @override
  int build() => 7;

  void set(int days) => state = days;
}

final _rangeDaysProvider = NotifierProvider<_RangeDays, int>(_RangeDays.new);

class DashboardData {
  const DashboardData({
    required this.days,
    required this.top,
    required this.payments,
    required this.staff,
    required this.refunds,
  });

  final List<DailyTotal> days;
  final List<TopProduct> top;
  final Map<PayMethod, Money> payments;
  final Map<String?, Money> staff;
  final Money refunds;

  Money get total => days.fold(Money.zero, (s, d) => s + d.total);
  int get count => days.fold(0, (s, d) => s + d.count);
  Money get avg => count == 0 ? Money.zero : Money(total.paisa ~/ count);
  Money get net => total - refunds;
}

final _dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final db = ref.watch(databaseProvider);
  final rangeDays = ref.watch(_rangeDaysProvider);
  final now = DateTime.now().toUtc();
  final end = DateTime.utc(now.year, now.month, now.day)
      .add(const Duration(days: 1));
  final start = end.subtract(Duration(days: rangeDays));
  final days = await db.salesDao.dailyTotals(start: start, end: end);
  final top = await db.salesDao.topProducts(start: start, end: end);
  final payments = await db.salesDao.paymentTotals(start: start, end: end);
  final staff = await db.salesDao.staffTotals(start: start, end: end);
  final refunds = await db.returnsDao.refundsInRange(start: start, end: end);
  return DashboardData(
      days: days,
      top: top,
      payments: payments,
      staff: staff,
      refunds: refunds);
});

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final rangeDays = ref.watch(_rangeDaysProvider);
    final data = ref.watch(_dashboardProvider);

    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (d) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(_dashboardProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Filter row above the charts (one row, dataviz interaction spec).
            Row(
              children: [
                SegmentedButton<int>(
                  segments: [
                    ButtonSegment(value: 1, label: Text(l10n.rangeToday)),
                    ButtonSegment(value: 7, label: Text(l10n.range7d)),
                    ButtonSegment(value: 30, label: Text(l10n.range30d)),
                  ],
                  selected: {rangeDays},
                  onSelectionChanged: (s) =>
                      ref.read(_rangeDaysProvider.notifier).set(s.first),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.invalidate(_dashboardProvider),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatCard(
                    label: l10n.todaySalesTotal.replaceFirst('today', '').trim(),
                    title: l10n.todaySalesTotal,
                    value: formatTaka(d.total, locale: locale),
                    icon: Icons.payments,
                    color: Theme.of(context).colorScheme.primary),
                _StatCard(
                    title: l10n.todayTransactions,
                    value: locale == 'bn'
                        ? toBanglaDigits('${d.count}')
                        : '${d.count}',
                    icon: Icons.receipt_long,
                    color: Theme.of(context).colorScheme.tertiary),
                _StatCard(
                    title: l10n.avgPerSale,
                    value: formatTaka(d.avg, locale: locale),
                    icon: Icons.trending_up,
                    color: Theme.of(context).colorScheme.secondary),
                if (d.refunds > Money.zero) ...[
                  _StatCard(
                      title: l10n.refundsToday,
                      value: '-${formatTaka(d.refunds, locale: locale)}',
                      icon: Icons.assignment_return,
                      color: Theme.of(context).colorScheme.error),
                  _StatCard(
                      title: l10n.netSales,
                      value: formatTaka(d.net, locale: locale),
                      icon: Icons.account_balance_wallet,
                      color: Theme.of(context).colorScheme.primary),
                ],
              ],
            ),
            const SizedBox(height: 16),
            if (d.days.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Center(child: Text(l10n.noData)),
                ),
              )
            else ...[
              _ChartCard(
                title: l10n.salesTrend,
                child: SizedBox(
                  height: 220,
                  child: _TrendChart(days: d.days, rangeDays: rangeDays),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ChartCard(
                      title: l10n.topProductsTitle,
                      child: _TopProductsList(top: d.top),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ChartCard(
                      title: l10n.paymentMethodsTitle,
                      child: _PaymentSplit(payments: d.payments),
                    ),
                  ),
                ],
              ),
              if (d.staff.isNotEmpty) ...[
                const SizedBox(height: 16),
                _ChartCard(
                  title: l10n.staffSalesTitle,
                  child: _StaffSales(staff: d.staff),
                ),
              ],
            ],
          ].animate(interval: 60.ms).fadeIn(duration: 250.ms),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {this.label,
      required this.title,
      required this.value,
      required this.icon,
      required this.color});

  final String? label;
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Container(
        width: 230,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.14), theme.colorScheme.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.18),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(value,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Single-series daily sales bars: thin marks, rounded data-ends, recessive
/// horizontal grid, tooltip on touch. Single series → no legend (title names it).
class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.days, required this.rangeDays});

  final List<DailyTotal> days;
  final int rangeDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final dark = theme.brightness == Brightness.dark;
    final series = dark ? _seriesDark : _seriesLight;
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
                value == 0 ? '0' : '৳${_compact(value)}',
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
              formatTaka(Money((rod.toY * 100).round()), locale: locale),
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

  String _compact(double taka) {
    if (taka >= 100000) return '${(taka / 100000).toStringAsFixed(1)}L';
    if (taka >= 1000) return '${(taka / 1000).toStringAsFixed(0)}k';
    return taka.toStringAsFixed(0);
  }
}

/// Ranked magnitude list: single hue bars + direct labels.
class _TopProductsList extends StatelessWidget {
  const _TopProductsList({required this.top});

  final List<TopProduct> top;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final dark = theme.brightness == Brightness.dark;
    final series = dark ? _seriesDark : _seriesLight;
    if (top.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(AppLocalizations.of(context).noData),
      );
    }
    final maxRevenue = top.first.revenue.paisa;
    return Column(
      children: [
        for (final p in top)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium),
                    ),
                    Text(formatTaka(p.revenue, locale: locale),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: maxRevenue == 0
                        ? 0
                        : p.revenue.paisa / maxRevenue,
                    minHeight: 6,
                    color: series,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Sales per staff member, resolving ids to names. Single-hue ranked bars.
class _StaffSales extends ConsumerWidget {
  const _StaffSales({required this.staff});

  final Map<String?, Money> staff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final dark = theme.brightness == Brightness.dark;
    final series = dark ? _seriesDark : _seriesLight;
    final names = {
      for (final s in ref.watch(staffListProvider).value ?? const <StaffData>[])
        s.id: s.name
    };
    final entries = staff.entries.toList()
      ..sort((a, b) => b.value.paisa.compareTo(a.value.paisa));
    final maxPaisa =
        entries.fold<int>(0, (m, e) => e.value.paisa > m ? e.value.paisa : m);

    return Column(
      children: [
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(names[e.key] ?? '—',
                          style: theme.textTheme.bodyMedium),
                    ),
                    Text(formatTaka(e.value, locale: locale),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: maxPaisa == 0 ? 0 : e.value.paisa / maxPaisa,
                    minHeight: 6,
                    color: series,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Identity split: one stacked horizontal bar with 2px surface gaps and a
/// chip legend carrying direct labels (name + amount).
class _PaymentSplit extends StatelessWidget {
  const _PaymentSplit({required this.payments});

  final Map<PayMethod, Money> payments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final colors = theme.brightness == Brightness.dark ? _payDark : _payLight;
    final labels = {
      PayMethod.cash: l10n.cashLabel,
      PayMethod.bkash: l10n.bkash,
      PayMethod.nagad: l10n.nagad,
      PayMethod.card: l10n.card,
    };
    final entries = [
      for (final m in PayMethod.values)
        if ((payments[m] ?? Money.zero) > Money.zero)
          MapEntry(m, payments[m]!),
    ];
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(l10n.noData),
      );
    }
    final total = entries.fold(0, (s, e) => s + e.value.paisa);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                for (final e in entries) ...[
                  Expanded(
                    flex: (e.value.paisa * 1000 ~/ total) + 1,
                    child: Container(color: colors[e.key]),
                  ),
                  if (e != entries.last) const SizedBox(width: 2),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in entries)
              Chip(
                avatar: CircleAvatar(backgroundColor: colors[e.key], radius: 6),
                label: Text(
                    '${labels[e.key]} · ${formatTaka(e.value, locale: locale)}'),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ],
    );
  }
}
