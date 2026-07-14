import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/brand.dart';
import '../../../app/providers.dart';
import '../../../app/widgets/product_picker.dart';
import '../../../core/db/database.dart';
import '../../../core/db/sale_draft.dart';
import '../../../core/format.dart';
import '../../../core/money.dart';
import '../../../core/printing/kot.dart';
import '../../../core/printing/print_service.dart';
import '../../../core/printing/receipt.dart';
import '../../../core/qty.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../pos/ui/receipt_dialog.dart';

/// Localised label for an order type ("Dine-in" / "Takeaway" / "Delivery").
String orderTypeLabel(AppLocalizations l10n, OrderType type) => switch (type) {
      OrderType.dineIn => l10n.orderTypeDineIn,
      OrderType.takeaway => l10n.orderTypeTakeaway,
      OrderType.delivery => l10n.orderTypeDelivery,
    };

Money _subtotalOf(List<DineOrderItem> items) => items.fold(
    Money.zero, (sum, i) => sum + i.unitPrice.timesQty(i.qty));

Money _vatOf(List<DineOrderItem> items) => items.fold(
    Money.zero,
    (sum, i) =>
        sum + i.unitPrice.timesQty(i.qty).vatPortionInclusive(i.vatRateBp));

/// The running-order surface: menu grid on the left, the live tab on the right.
/// Items persist to the DB as they're added, so the tab survives navigation and
/// restarts. From here the waiter fires a kitchen ticket and settles the bill.
class OrderEditorScreen extends ConsumerWidget {
  const OrderEditorScreen({super.key, required this.order, required this.title});

  final DineOrder order;

  /// Human label for the order (table name, or guest/order type).
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        // Explicit back affordance to the floor/hub, always available.
        leading: const BackButton(),
        title: Text(title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(label: Text(orderTypeLabel(l10n, order.orderType))),
          ),
          IconButton(
            tooltip: l10n.cancelOrder,
            icon: const Icon(Icons.delete_forever),
            onPressed: () => _confirmCancel(context, ref),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: ProductPicker(
              onPick: (p) =>
                  ref.read(databaseProvider).ordersDao.addProduct(order.id, p),
              emptyBuilder: (_) => Center(child: Text(l10n.noProducts)),
            ),
          ),
          const VerticalDivider(width: 1),
          SizedBox(width: 380, child: _OrderPane(order: order, title: title)),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l10n.cancelOrder),
        content: Text(l10n.cancelOrderConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dctx).pop(false),
              child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dctx).colorScheme.error),
            onPressed: () => Navigator.of(dctx).pop(true),
            child: Text(l10n.cancelOrder),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(databaseProvider).ordersDao.cancelOrder(order.id);
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(l10n.orderCancelled)));
  }
}

class _OrderPane extends ConsumerWidget {
  const _OrderPane({required this.order, required this.title});

  final DineOrder order;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final itemsAsync = ref.watch(orderItemsProvider(order.id));
    final items = itemsAsync.value ?? const <DineOrderItem>[];
    final subtotal = _subtotalOf(items);
    final vat = _vatOf(items);
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
                  builder: (_) => _ManualItemDialog(orderId: order.id),
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
                          '${formatTaka(line.unitPrice, locale: locale)} × ${line.qty.display}'
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
                                  locale: locale),
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
              _row(context, l10n.subtotal, formatTaka(subtotal, locale: locale)),
              if (!vat.isZero)
                _row(context, l10n.vat, formatTaka(vat, locale: locale)),
              const SizedBox(height: 4),
              _row(context, l10n.total, formatTaka(subtotal, locale: locale),
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
                            builder: (_) => _SettleDialog(
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

class _ManualItemDialog extends ConsumerStatefulWidget {
  const _ManualItemDialog({required this.orderId});

  final String orderId;

  @override
  ConsumerState<_ManualItemDialog> createState() => _ManualItemDialogState();
}

class _ManualItemDialogState extends ConsumerState<_ManualItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _qty = TextEditingController(text: '1');

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.manualItem),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                decoration: InputDecoration(labelText: l10n.productName),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                decoration: InputDecoration(labelText: l10n.price),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  try {
                    Money.parse(v ?? '');
                    return null;
                  } on FormatException {
                    return l10n.invalidAmount;
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _qty,
                decoration: InputDecoration(labelText: l10n.quantity),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  try {
                    Qty.parse(v ?? '');
                    return null;
                  } on FormatException {
                    return l10n.invalidAmount;
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            final navigator = Navigator.of(context);
            await ref.read(databaseProvider).ordersDao.addManual(
                  widget.orderId,
                  name: _name.text.trim(),
                  price: Money.parse(_price.text),
                  qty: Qty.parse(_qty.text),
                );
            navigator.pop();
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// Settle a running order: split-tender payment, then finalize to an immutable
/// sale (the same engine as retail) and pop back to the floor/hub.
class _SettleDialog extends ConsumerStatefulWidget {
  const _SettleDialog(
      {required this.order, required this.subtotal, required this.vat});

  final DineOrder order;
  final Money subtotal;
  final Money vat;

  @override
  ConsumerState<_SettleDialog> createState() => _SettleDialogState();
}

class _SettleDialogState extends ConsumerState<_SettleDialog> {
  late final TextEditingController _cash;
  final _bkash = TextEditingController();
  final _nagad = TextEditingController();
  final _card = TextEditingController();
  String? _customerId;

  Money get _total => widget.subtotal;

  @override
  void initState() {
    super.initState();
    _cash = TextEditingController(text: _total.asDecimalString);
  }

  @override
  void dispose() {
    _cash.dispose();
    _bkash.dispose();
    _nagad.dispose();
    _card.dispose();
    super.dispose();
  }

  Money? _parse(TextEditingController c) {
    final text = c.text.trim();
    if (text.isEmpty) return Money.zero;
    try {
      final m = Money.parse(text);
      return m.isNegative ? null : m;
    } on FormatException {
      return null;
    }
  }

  Map<PayMethod, Money>? get _tenders {
    final cash = _parse(_cash);
    final bkash = _parse(_bkash);
    final nagad = _parse(_nagad);
    final card = _parse(_card);
    if (cash == null || bkash == null || nagad == null || card == null) {
      return null;
    }
    return {
      PayMethod.cash: cash,
      PayMethod.bkash: bkash,
      PayMethod.nagad: nagad,
      PayMethod.card: card,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final customers = ref.watch(customersProvider).value ?? const <Customer>[];
    final tenders = _tenders;
    final tendered = tenders?.values
        .fold(Money.zero, (Money sum, Money amount) => sum + amount);
    final due = tendered != null && tendered < _total
        ? _total - tendered
        : Money.zero;
    final change = tendered != null && tendered > _total
        ? tendered - _total
        : Money.zero;
    final canConfirm =
        tendered != null && (tendered >= _total || _customerId != null);

    return AlertDialog(
      title: Text(l10n.settleOrder),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(formatTaka(_total, locale: locale),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _customerId,
                decoration: InputDecoration(labelText: l10n.customerLabel),
                items: [
                  DropdownMenuItem<String?>(
                      value: null, child: Text(l10n.walkIn)),
                  for (final c in customers)
                    DropdownMenuItem<String?>(
                        value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _customerId = v),
              ),
              const SizedBox(height: 12),
              _tenderField(_cash, l10n.cashLabel, autofocus: true),
              _tenderField(_bkash, l10n.bkash),
              _tenderField(_nagad, l10n.nagad),
              _tenderField(_card, l10n.card),
              const SizedBox(height: 8),
              if (tenders == null)
                Text(l10n.invalidAmount,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error))
              else if (!due.isZero)
                Text(l10n.willBeDue(formatTaka(due, locale: locale)),
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error))
              else
                Text('${l10n.change}: ${formatTaka(change, locale: locale)}'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: canConfirm ? _settle : null,
          child: Text(l10n.settleOrder),
        ),
      ],
    );
  }

  Widget _tenderField(TextEditingController controller, String label,
      {bool autofocus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Future<void> _settle() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final dialogNavigator = Navigator.of(context);
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    final db = ref.read(databaseProvider);
    final tenders = _tenders!;
    final tendered =
        tenders.values.fold(Money.zero, (Money s, Money a) => s + a);
    final change = tendered > _total ? tendered - _total : Money.zero;

    final sale = await db.ordersDao.settleOrder(
      orderId: widget.order.id,
      customerId: _customerId,
      tenders: [
        for (final entry in tenders.entries)
          if (!entry.value.isZero)
            TenderDraft(method: entry.key, amount: entry.value),
      ],
    );
    if (_customerId != null) {
      ref.invalidate(customerDueProvider(_customerId!));
    }

    final items = await db.salesDao.itemsOf(sale.id);
    final settings = db.settingsDao;
    final receipt = receiptFromSale(
      sale: sale,
      items: items,
      shopName: await settings.getValue('shop.name') ?? Brand.name,
      address: await settings.getValue('shop.address'),
      phone: await settings.getValue('shop.phone'),
      footer: await settings.getValue('receipt.footer') ??
          'Powered by ${Brand.name}',
      change: change,
    );
    final width =
        int.tryParse(await settings.getValue('printer.width') ?? '') ?? 32;
    final text = renderReceiptText(receipt, width: width);

    if (!mounted) return;
    // Return success so the editor (which owns the correct navigator) pops
    // itself back to the floor/hub.
    dialogNavigator.pop(true);
    messenger
        .showSnackBar(SnackBar(content: Text(l10n.orderSettled(sale.invoiceNo))));
    if (!rootContext.mounted) return;
    showDialog<void>(
      context: rootContext,
      builder: (_) => ReceiptDialog(text: text, invoiceNo: sale.invoiceNo),
    );
  }
}
