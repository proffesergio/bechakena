import '../../../settings/ui/business_settings_status.dart';
import '../../../../app/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/logic/session.dart';
import '../../../../core/db/database.dart';
import '../../../../core/format.dart';
import '../../../../core/money.dart';
import 'chart_style.dart';

/// Sales per staff member, resolving ids to names. Single-hue ranked bars.
class StaffSalesList extends ConsumerWidget {
  const StaffSalesList({super.key, required this.staff});

  final Map<String?, Money> staff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsStatus = businessSettingsStatus(ref, context);
    if (settingsStatus != null) return settingsStatus;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final series = seriesColor(context);
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
                    Text(formatTaka(e.value, locale: locale, currency: ref.read(shopCurrencyProvider)),
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
