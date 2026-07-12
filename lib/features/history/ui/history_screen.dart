import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/brand.dart';
import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../../../core/format.dart';
import '../../../core/money.dart';
import '../../../core/qty.dart';
import '../../../core/printing/print_service.dart';
import '../../../core/printing/receipt.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/logic/session.dart';
import '../../pos/ui/receipt_dialog.dart';

/// Recent sales with reprint and the return/refund flow (the correction path
/// for immutable finalized sales).
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final sales = ref.watch(recentSalesProvider);

    return sales.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (rows) => rows.isEmpty
          ? Center(child: Text(l10n.noSales))
          : ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final s = rows[i];
                return ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: Text(s.invoiceNo),
                  subtitle: Text(
                      '${s.createdAt.toLocal().toString().substring(0, 16)}'
                      '${s.due > Money.zero ? ' · ${l10n.dueLabel} ${formatTaka(s.due, locale: locale)}' : ''}'),
                  trailing: Text(formatTaka(s.total, locale: locale),
                      style: Theme.of(context).textTheme.titleMedium),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => _SaleDetailDialog(sale: s),
                  ),
                );
              },
            ),
    );
  }
}

class _SaleDetailDialog extends ConsumerWidget {
  const _SaleDetailDialog({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final itemsAsync = ref.watch(_saleItemsProvider(sale.id));

    return AlertDialog(
      title: Text(l10n.saleDetail(sale.invoiceNo)),
      content: SizedBox(
        width: 420,
        child: itemsAsync.when(
          loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Text('$e'),
          data: (items) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final it in items)
                ListTile(
                  dense: true,
                  title: Text(it.nameSnapshot),
                  subtitle: Text(
                      '${it.qty.display} × ${formatTaka(it.unitPrice, locale: locale)}'),
                  trailing:
                      Text(formatTaka(it.lineTotal, locale: locale)),
                ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.total,
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(formatTaka(sale.total, locale: locale),
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.print),
          label: Text(l10n.reprint),
          onPressed: () => _reprint(context, ref),
        ),
        TextButton.icon(
          icon: const Icon(Icons.assignment_return),
          label: Text(l10n.returnItems),
          onPressed: () {
            final items = itemsAsync.value;
            if (items == null || items.isEmpty) return;
            Navigator.of(context).pop();
            showDialog<void>(
              context: context,
              builder: (_) => _ReturnDialog(sale: sale, items: items),
            );
          },
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  Future<void> _reprint(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    final db = ref.read(databaseProvider);
    final settings = db.settingsDao;
    final items = await db.salesDao.itemsOf(sale.id);
    final receipt = receiptFromSale(
      sale: sale,
      items: items,
      shopName: await settings.getValue('shop.name') ?? Brand.name,
      address: await settings.getValue('shop.address'),
      phone: await settings.getValue('shop.phone'),
      footer:
          await settings.getValue('receipt.footer') ?? 'Powered by ${Brand.name}',
    );
    final width =
        int.tryParse(await settings.getValue('printer.width') ?? '') ?? 32;
    final text = renderReceiptText(receipt, width: width);
    navigator.pop();
    if (!rootContext.mounted) return;
    showDialog<void>(
      context: rootContext,
      builder: (_) => ReceiptDialog(text: text),
    );
  }
}

/// Per-sale items, fetched once for the detail dialog.
final _saleItemsProvider =
    FutureProvider.family<List<SaleItem>, String>((ref, saleId) =>
        ref.watch(databaseProvider).salesDao.itemsOf(saleId));

class _ReturnDialog extends ConsumerStatefulWidget {
  const _ReturnDialog({required this.sale, required this.items});

  final Sale sale;
  final List<SaleItem> items;

  @override
  ConsumerState<_ReturnDialog> createState() => _ReturnDialogState();
}

class _ReturnDialogState extends ConsumerState<_ReturnDialog> {
  // Return quantity per item index, in milli-units.
  late final List<int> _returnMilli =
      List<int>.filled(widget.items.length, 0);

  /// Proportional refund for a partial return of a line.
  Money _refundFor(SaleItem item, int returnMilli) {
    if (item.qty.milli == 0) return Money.zero;
    return Money((item.lineTotal.paisa * returnMilli) ~/ item.qty.milli);
  }

  Money get _refundTotal {
    var total = Money.zero;
    for (var i = 0; i < widget.items.length; i++) {
      total += _refundFor(widget.items[i], _returnMilli[i]);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final canConfirm = _returnMilli.any((m) => m > 0);

    return AlertDialog(
      title: Text(l10n.returnItems),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.items.length; i++)
                _returnRow(i, locale, l10n),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.refundTotal,
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(formatTaka(_refundTotal, locale: locale),
                      style: Theme.of(context).textTheme.titleMedium),
                ],
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
          onPressed: canConfirm ? _confirm : null,
          child: Text(l10n.confirmReturn),
        ),
      ],
    );
  }

  Widget _returnRow(int i, String locale, AppLocalizations l10n) {
    final item = widget.items[i];
    final soldMilli = item.qty.milli;
    final current = _returnMilli[i];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.nameSnapshot),
                Text('${item.qty.display} × ${formatTaka(item.unitPrice, locale: locale)}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: current <= 0
                ? null
                : () => setState(() =>
                    _returnMilli[i] = (current - 1000).clamp(0, soldMilli)),
          ),
          Text(Qty(current).display),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: current >= soldMilli
                ? null
                : () => setState(() =>
                    _returnMilli[i] = (current + 1000).clamp(0, soldMilli)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final db = ref.read(databaseProvider);

    final drafts = <ReturnDraftItem>[];
    for (var i = 0; i < widget.items.length; i++) {
      final milli = _returnMilli[i];
      if (milli <= 0) continue;
      final item = widget.items[i];
      drafts.add(ReturnDraftItem(
        productId: item.productId,
        nameSnapshot: item.nameSnapshot,
        qty: Qty(milli),
        refundAmount: _refundFor(item, milli),
      ));
    }
    final refund = _refundTotal;
    await db.returnsDao.createReturn(
      originalSaleId: widget.sale.id,
      staffId: ref.read(currentStaffProvider)?.id,
      items: drafts,
    );
    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(SnackBar(
        content: Text(l10n.returnDone(formatTaka(refund, locale: locale)))));
  }
}
