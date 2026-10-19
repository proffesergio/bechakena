import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../settings/ui/business_settings_status.dart';
import '../../../../app/providers.dart';
import 'package:flutter/material.dart';

import '../../../../core/db/database.dart';
import '../../../../core/format.dart';
import '../../../../core/money.dart';
import '../../../../l10n/gen/app_localizations.dart';
import 'chart_style.dart';

/// Identity split: one stacked horizontal bar with 2px surface gaps and a
/// chip legend carrying direct labels (name + amount).
class PaymentSplit extends ConsumerWidget {
  const PaymentSplit({super.key, required this.payments});

  final Map<PayMethod, Money> payments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsStatus = businessSettingsStatus(ref, context);
    if (settingsStatus != null) return settingsStatus;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final colors =
        theme.brightness == Brightness.dark ? payColorsDark : payColorsLight;
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
                    '${labels[e.key]} · ${formatTaka(e.value, locale: locale, currency: ref.read(shopCurrencyProvider))}'),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ],
    );
  }
}
