import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/product_visuals.dart';
import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../../../core/format.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Inventory alerts: products at/below their low-stock level, and purchase
/// batches expiring within 14 days (already-expired included).
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final low = ref.watch(lowStockProvider);
    final expiring = ref.watch(expiringSoonProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(lowStockProvider);
        ref.invalidate(expiringSoonProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(
              icon: Icons.production_quantity_limits,
              title: l10n.lowStockTitle,
              color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 8),
          low.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (rows) => rows.isEmpty
                ? _EmptyLine(l10n.noAlerts)
                : Column(
                    children: [for (final r in rows) _LowStockTile(row: r)],
                  ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
              icon: Icons.event_busy,
              title: l10n.expiringSoonTitle,
              color: Theme.of(context).colorScheme.tertiary),
          const SizedBox(height: 8),
          expiring.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (rows) => rows.isEmpty
                ? _EmptyLine(l10n.noAlerts)
                : Column(
                    children: [for (final b in rows) _ExpiringTile(batch: b)],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.icon, required this.title, required this.color});

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: const Icon(Icons.check_circle_outline),
          title: Text(text),
        ),
      );
}

class _LowStockTile extends StatelessWidget {
  const _LowStockTile({required this.row});
  final LowStockRow row;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final emoji = productEmoji(row.product);
    return Card(
      child: ListTile(
        leading: emoji != null
            ? Text(emoji, style: const TextStyle(fontSize: 28))
            : const Icon(Icons.inventory_2),
        title: Text(row.product.name),
        subtitle: Text(l10n.stockLabel(row.stock.display)),
        trailing: Chip(
          label: Text(row.stock.display),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      ),
    );
  }
}

class _ExpiringTile extends StatelessWidget {
  const _ExpiringTile({required this.batch});
  final ExpiringBatch batch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final emoji = productEmoji(batch.product);
    final now = DateTime.now().toUtc();
    final expired = batch.expiryDate.isBefore(now);
    final dateStr =
        '${batch.expiryDate.day}/${batch.expiryDate.month}/${batch.expiryDate.year % 100}';
    return Card(
      child: ListTile(
        leading: emoji != null
            ? Text(emoji, style: const TextStyle(fontSize: 28))
            : const Icon(Icons.inventory_2),
        title: Text(batch.product.name),
        subtitle: Text(batch.qty.display),
        trailing: Chip(
          label: Text(expired
              ? l10n.expired
              : l10n.expiresOn(
                  locale == 'bn' ? toBanglaDigits(dateStr) : dateStr)),
          backgroundColor: expired
              ? Theme.of(context).colorScheme.errorContainer
              : Theme.of(context).colorScheme.tertiaryContainer,
        ),
      ),
    );
  }
}
