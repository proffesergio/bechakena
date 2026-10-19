import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../settings/ui/business_settings_status.dart';
import '../../../../app/providers.dart';
import 'package:flutter/material.dart';

import '../../../../core/db/database.dart';
import '../../../../core/format.dart';
import '../../../../l10n/gen/app_localizations.dart';
import 'chart_style.dart';

/// Ranked magnitude list: single hue bars + direct labels.
class TopProductsList extends ConsumerWidget {
  const TopProductsList({super.key, required this.top});

  final List<TopProduct> top;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsStatus = businessSettingsStatus(ref, context);
    if (settingsStatus != null) return settingsStatus;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final series = seriesColor(context);
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
                    Text(formatTaka(p.revenue, locale: locale, currency: ref.read(shopCurrencyProvider)),
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
