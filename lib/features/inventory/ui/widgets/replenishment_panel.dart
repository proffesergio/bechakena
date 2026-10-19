import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/csv/product_csv.dart';
import '../../../../core/platform/files.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../logic/replenishment_provider.dart';

class ReplenishmentPanel extends ConsumerStatefulWidget {
  const ReplenishmentPanel({super.key});
  @override
  ConsumerState<ReplenishmentPanel> createState() => _ReplenishmentPanelState();
}

class _ReplenishmentPanelState extends ConsumerState<ReplenishmentPanel> {
  int _lead = 7;
  int _cover = 14;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(
      replenishmentProvider((leadDays: _lead, coverDays: _cover)),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.replenishTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(l.replenishHint),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<int>(
                    initialValue: _lead,
                    decoration: InputDecoration(labelText: l.replenishLead),
                    items: [
                      for (final n in [0, 3, 7, 14, 30])
                        DropdownMenuItem(
                          value: n,
                          child: Text(l.replenishDays(n)),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _lead = v);
                    },
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<int>(
                    initialValue: _cover,
                    decoration: InputDecoration(labelText: l.replenishCover),
                    items: [
                      for (final n in [7, 14, 28, 60])
                        DropdownMenuItem(
                          value: n,
                          child: Text(l.replenishDays(n)),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _cover = v);
                    },
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.download),
                  label: Text(l.replenishExport),
                  onPressed: data.value == null || data.value!.isEmpty
                      ? null
                      : () => _export(data.value!),
                ),
              ],
            ),
            const SizedBox(height: 16),
            data.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => Text(l.replenishError),
              data: (rows) => rows.isEmpty
                  ? Text(l.replenishEmpty)
                  : Column(
                      children: [
                        for (final row in rows)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.auto_graph),
                            title: Text(row.name),
                            subtitle: Text(
                              l.replenishStockSales(
                                row.stock.display,
                                row.sold.display,
                                row.unit,
                              ),
                            ),
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${row.plan.suggested.display} ${row.unit}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Text(
                                  row.plan.daysRemaining == null
                                      ? l.replenishNoHistory
                                      : l.replenishDays(
                                          row.plan.daysRemaining!,
                                        ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export(List<ReplenishmentRow> rows) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // Neutralize spreadsheet formulas originating from editable product names.
    String safe(String s) => RegExp(r'^[\s]*[=+@-]').hasMatch(s) ? "'$s" : s;
    try {
      await saveTextFile(
        'replenishment-plan.csv',
        encodeCsv([
          [
            'product',
            'unit',
            'stock',
            'sold_28_days',
            'suggested_order',
            'days_cover',
            'lead_days',
            'target_cover_days',
          ],
          for (final row in rows)
            [
              safe(row.name),
              safe(row.unit),
              row.stock.display,
              row.sold.display,
              row.plan.suggested.display,
              '${row.plan.daysRemaining ?? ''}',
              '$_lead',
              '$_cover',
            ],
        ]),
      );
      messenger.showSnackBar(SnackBar(content: Text(l.replenishExported)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.replenishError)));
    }
  }
}
