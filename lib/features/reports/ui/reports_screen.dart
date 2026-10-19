import '../../settings/ui/business_settings_status.dart';
import '../../../app/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/money.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../logic/dashboard.dart';
import 'widgets/chart_style.dart';
import 'widgets/payment_split.dart';
import 'widgets/sales_trend_chart.dart';
import 'widgets/stat_card.dart';
import 'widgets/staff_sales_list.dart';
import 'widgets/top_products_list.dart';

/// Sales dashboard orchestrator: range filter, headline stats and the
/// trend / top-products / payment / staff chart widgets (see `widgets/`).
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsStatus = businessSettingsStatus(ref, context);
    if (settingsStatus != null) return settingsStatus;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final rangeDays = ref.watch(rangeDaysProvider);
    final data = ref.watch(dashboardProvider);

    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (d) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardProvider),
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
                      ref.read(rangeDaysProvider.notifier).set(s.first),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.invalidate(dashboardProvider),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                StatCard(
                    label: l10n.todaySalesTotal.replaceFirst('today', '').trim(),
                    title: l10n.todaySalesTotal,
                    value: formatTaka(d.total, locale: locale, currency: ref.read(shopCurrencyProvider)),
                    icon: Icons.payments,
                    color: Theme.of(context).colorScheme.primary),
                StatCard(
                    title: l10n.todayTransactions,
                    value: locale == 'bn'
                        ? toBanglaDigits('${d.count}')
                        : '${d.count}',
                    icon: Icons.receipt_long,
                    color: Theme.of(context).colorScheme.tertiary),
                StatCard(
                    title: l10n.avgPerSale,
                    value: formatTaka(d.avg, locale: locale, currency: ref.read(shopCurrencyProvider)),
                    icon: Icons.trending_up,
                    color: Theme.of(context).colorScheme.secondary),
                if (d.refunds > Money.zero) ...[
                  StatCard(
                      title: l10n.refundsToday,
                      value: '-${formatTaka(d.refunds, locale: locale, currency: ref.read(shopCurrencyProvider))}',
                      icon: Icons.assignment_return,
                      color: Theme.of(context).colorScheme.error),
                  StatCard(
                      title: l10n.netSales,
                      value: formatTaka(d.net, locale: locale, currency: ref.read(shopCurrencyProvider)),
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
              ChartCard(
                title: l10n.salesTrend,
                child: SizedBox(
                  height: 220,
                  child:
                      SalesTrendChart(days: d.days, rangeDays: rangeDays),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ChartCard(
                      title: l10n.topProductsTitle,
                      child: TopProductsList(top: d.top),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ChartCard(
                      title: l10n.paymentMethodsTitle,
                      child: PaymentSplit(payments: d.payments),
                    ),
                  ),
                ],
              ),
              if (d.staff.isNotEmpty) ...[
                const SizedBox(height: 16),
                ChartCard(
                  title: l10n.staffSalesTitle,
                  child: StaffSalesList(staff: d.staff),
                ),
              ],
            ],
          ].animate(interval: 60.ms).fadeIn(duration: 250.ms),
        ),
      ),
    );
  }
}
