import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../../../core/format.dart';
import '../../../core/money.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/logic/session.dart';
import 'order_editor_screen.dart';

/// Restaurant home: every open tab (dine-in, takeaway, delivery) at a glance,
/// plus one-tap start for a takeaway or delivery order. Dine-in tabs are opened
/// from the Floor (Tables) screen but also surface here so nothing is missed.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final orders = ref.watch(openOrdersProvider);
    final tables = ref.watch(diningTablesProvider).value ?? const <DiningTable>[];
    final tableName = {for (final t in tables) t.id: t.name};

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.openOrders),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.takeout_dining),
            label: Text(l10n.newTakeaway),
            onPressed: () => _startCounterOrder(context, ref, OrderType.takeaway),
          ),
          TextButton.icon(
            icon: const Icon(Icons.delivery_dining),
            label: Text(l10n.newDelivery),
            onPressed: () => _startCounterOrder(context, ref, OrderType.delivery),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => list.isEmpty
            ? Center(child: Text(l10n.noOpenOrders))
            : GridView.extent(
                padding: const EdgeInsets.all(16),
                maxCrossAxisExtent: 260,
                childAspectRatio: 1.5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  for (final o in list)
                    _OrderCard(order: o, label: _label(l10n, o, tableName)),
                ],
              ),
      ),
    );
  }

  String _label(
      AppLocalizations l10n, DineOrder o, Map<String, String> tableName) {
    if (o.orderType == OrderType.dineIn) {
      return o.tableId != null
          ? (tableName[o.tableId] ?? l10n.orderTypeDineIn)
          : l10n.orderTypeDineIn;
    }
    return o.customerName?.trim().isNotEmpty == true
        ? o.customerName!.trim()
        : l10n.guest;
  }

  Future<void> _startCounterOrder(
      BuildContext context, WidgetRef ref, OrderType type) async {
    final name = await showDialog<String?>(
      context: context,
      builder: (_) => const _GuestNameDialog(),
    );
    // A null result means the dialog was dismissed — don't start an order.
    if (name == null) return;
    if (!context.mounted) return;
    final navigator = Navigator.of(context);
    final l10n = AppLocalizations.of(context);
    final order = await ref.read(databaseProvider).ordersDao.createOrder(
          orderType: type,
          staffId: ref.read(currentStaffProvider)?.id,
          customerName: name.isEmpty ? null : name,
        );
    navigator.push(MaterialPageRoute<void>(
      builder: (_) => OrderEditorScreen(
          order: order, title: name.isEmpty ? orderTypeLabel(l10n, type) : name),
    ));
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order, required this.label});

  final DineOrder order;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final items =
        ref.watch(orderItemsProvider(order.id)).value ?? const <DineOrderItem>[];
    final total = items.fold(
        Money.zero, (Money s, i) => s + i.unitPrice.timesQty(i.qty));
    final unsent = items.where((i) => !i.kotSent).length;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => OrderEditorScreen(order: order, title: label),
        )),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(switch (order.orderType) {
                    OrderType.dineIn => Icons.table_restaurant,
                    OrderType.takeaway => Icons.takeout_dining,
                    OrderType.delivery => Icons.delivery_dining,
                  }),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  if (unsent > 0)
                    Badge(label: Text('$unsent')),
                ],
              ),
              const Spacer(),
              Text(orderTypeLabel(l10n, order.orderType),
                  style: Theme.of(context).textTheme.bodySmall),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.itemsCount(items.length.toString()),
                      style: Theme.of(context).textTheme.bodySmall),
                  Text(formatTaka(total, locale: locale),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Optional guest name / phone for a takeaway or delivery order. Returns the
/// entered name (possibly empty) on confirm, or null if dismissed.
class _GuestNameDialog extends StatefulWidget {
  const _GuestNameDialog();

  @override
  State<_GuestNameDialog> createState() => _GuestNameDialogState();
}

class _GuestNameDialogState extends State<_GuestNameDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.guestName),
      content: SizedBox(
        width: 320,
        child: TextField(
          controller: _name,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.guestName),
          onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_name.text.trim()),
          child: Text(l10n.addToOrder),
        ),
      ],
    );
  }
}
