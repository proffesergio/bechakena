import '../../../settings/ui/business_settings_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/db/database.dart';
import '../../../../core/format.dart';
import '../../../../core/printing/kot.dart';
import '../../../../core/qty.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../pos/ui/receipt_dialog.dart';
import '../../logic/order_math.dart';
import 'manual_item_dialog.dart';
import 'settle_dialog.dart';

/// The live tab pane of the order editor: line list with qty steppers,
/// totals, "send to kitchen" (KOT) and settle actions.
class OrderPane extends ConsumerWidget {
  const OrderPane({super.key, required this.order, required this.title});

  final DineOrder order;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsStatus = businessSettingsStatus(ref, context);
    if (settingsStatus != null) return settingsStatus;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final itemsAsync = ref.watch(orderItemsProvider(order.id));
    final items = itemsAsync.value ?? const <DineOrderItem>[];
    final subtotal = subtotalOfItems(items);
    final vat = vatOfItems(items);
    final unsent = items.where((i) => !i.kotSent).length;
    final dao = ref.read(databaseProvider).ordersDao;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(l10n.orderPanel,
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                tooltip: l10n.manualItem,
                icon: const Icon(Icons.playlist_add),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => ManualItemDialog(orderId: order.id),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child:
                        Text(l10n.noOrderItems, textAlign: TextAlign.center),
                  ),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final line = items[i];
                    return ListTile(
                      dense: true,
                      title: Text(line.nameSnapshot),
                      subtitle: Text(
                          '${formatTaka(line.unitPrice, locale: locale, currency: ref.read(shopCurrencyProvider))} × ${line.qty.display}'
                          '${line.kotSent ? '  ·  ✓' : ''}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => dao.setQty(
                                line.id, line.qty - Qty.fromCount(1)),
                          ),
                          Text(line.qty.display),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => dao.setQty(
                                line.id, line.qty + Qty.fromCount(1)),
                          ),
                          SizedBox(
                            width: 72,
                            child: Text(
                              formatTaka(line.unitPrice.timesQty(line.qty),
                                  locale: locale, currency: ref.read(shopCurrencyProvider)),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _row(context, l10n.subtotal, formatTaka(subtotal, locale: locale, currency: ref.read(shopCurrencyProvider))),
              if (!vat.isZero)
                _row(context, ref.watch(businessSettingsProvider).requireValue.taxLabel, formatTaka(vat, locale: locale, currency: ref.read(shopCurrencyProvider))),
              const SizedBox(height: 4),
              _row(context, l10n.total, formatTaka(subtotal, locale: locale, currency: ref.read(shopCurrencyProvider)),
                  emphasize: true),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.soup_kitchen),
                      label: Text(unsent > 0
                          ? '${l10n.sendToKitchen} (${l10n.newItemsToFire(unsent.toString())})'
                          : l10n.sendToKitchen),
                      onPressed:
                          items.isEmpty ? null : () => _sendKot(context, ref),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  icon: const Icon(Icons.payments),
                  label: Text(l10n.settleOrder),
                  onPressed: items.isEmpty
                      ? null
                      : () async {
                          // Settle in a dialog; on success pop the editor from
                          // *this* context (the editor's own navigator) rather
                          // than from inside the dialog, whose nearest navigator
                          // is the root — popping that blanks the whole shell.
                          final settled = await showDialog<bool>(
                            context: context,
                            builder: (_) => SettleDialog(
                                order: order, subtotal: subtotal, vat: vat),
                          );
                          if (settled == true && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _sendKot(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final dao = ref.read(databaseProvider).ordersDao;
    final settings = ref.read(databaseProvider).settingsDao;
    final unsent = await dao.unsentItems(order.id);
    if (unsent.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.nothingNewToSend)));
      return;
    }
    final width =
        int.tryParse(await settings.getValue('printer.width') ?? '') ?? 32;
    final text = renderKotText(
      title: l10n.kitchenTicket,
      orderLabel: '${orderTypeLabel(l10n, order.orderType)} · $title',
      at: DateTime.now(),
      items: [
        for (final i in unsent)
          KotLine(name: i.nameSnapshot, qty: i.qty, note: i.note),
      ],
      width: width,
    );
    await dao.markKotSent(order.id);
    if (!context.mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(l10n.sentToKitchen)));
    showDialog<void>(
      context: context,
      builder: (_) => ReceiptDialog(text: text, kickDrawer: false),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {bool emphasize = false}) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(value, style: style)],
    );
  }
}
