import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../../../core/format.dart';
import '../../../core/money.dart';
import '../../../core/qty.dart';
import '../../../l10n/gen/app_localizations.dart';

final purchasesProvider = StreamProvider<List<Purchase>>(
    (ref) => ref.watch(databaseProvider).purchasesDao.watchRecent());

final suppliersProvider = StreamProvider<List<Supplier>>(
    (ref) => ref.watch(databaseProvider).purchasesDao.watchSuppliers());

class PurchasesScreen extends ConsumerWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final purchases = ref.watch(purchasesProvider);

    return Scaffold(
      body: purchases.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) => all.isEmpty
            ? Center(child: Text(l10n.noPurchases))
            : ListView.separated(
                itemCount: all.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final p = all[i];
                  return ListTile(
                    leading: const Icon(Icons.local_shipping),
                    title: Text(p.invoiceRef ?? p.createdAt.toLocal().toString().substring(0, 16)),
                    subtitle: Text(p.createdAt.toLocal().toString().substring(0, 16)),
                    trailing: Text(
                      formatTaka(p.totalCost, locale: locale),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l10n.newPurchase),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const NewPurchaseDialog(),
        ),
      ),
    );
  }
}

class _PurchaseRow {
  String? productId;
  final qty = TextEditingController();
  final cost = TextEditingController();
  final expiry = TextEditingController();

  void dispose() {
    qty.dispose();
    cost.dispose();
    expiry.dispose();
  }
}

class NewPurchaseDialog extends ConsumerStatefulWidget {
  const NewPurchaseDialog({super.key});

  @override
  ConsumerState<NewPurchaseDialog> createState() => _NewPurchaseDialogState();
}

class _NewPurchaseDialogState extends ConsumerState<NewPurchaseDialog> {
  final _invoiceRef = TextEditingController();
  String? _supplierId;
  final List<_PurchaseRow> _rows = [_PurchaseRow()];

  @override
  void dispose() {
    _invoiceRef.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  List<PurchaseDraftItem>? _draftItems() {
    final items = <PurchaseDraftItem>[];
    for (final row in _rows) {
      if (row.productId == null && row.qty.text.trim().isEmpty) continue;
      if (row.productId == null) return null;
      try {
        final qty = Qty.parse(row.qty.text);
        final cost = Money.parse(row.cost.text);
        DateTime? expiry;
        final expiryText = row.expiry.text.trim();
        if (expiryText.isNotEmpty) {
          expiry = DateTime.tryParse(expiryText);
          if (expiry == null) return null;
        }
        if (qty.isZero || qty.isNegative || cost.isNegative) return null;
        items.add(PurchaseDraftItem(
            productId: row.productId!,
            qty: qty,
            unitCost: cost,
            expiryDate: expiry));
      } on FormatException {
        return null;
      }
    }
    return items.isEmpty ? null : items;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final products = ref.watch(productsProvider).value ?? const <Product>[];
    final suppliers = ref.watch(suppliersProvider).value ?? const <Supplier>[];
    final items = _draftItems();
    var total = Money.zero;
    for (final item in items ?? const <PurchaseDraftItem>[]) {
      total += item.unitCost.timesQty(item.qty);
    }

    return AlertDialog(
      title: Text(l10n.newPurchase),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: _supplierId,
                      decoration: InputDecoration(labelText: l10n.supplier),
                      items: [
                        DropdownMenuItem<String?>(
                            value: null, child: Text('—')),
                        for (final s in suppliers)
                          DropdownMenuItem<String?>(
                              value: s.id, child: Text(s.name)),
                      ],
                      onChanged: (v) => setState(() => _supplierId = v),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.addSupplier,
                    icon: const Icon(Icons.add_business),
                    onPressed: () => _addSupplier(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _invoiceRef,
                decoration: InputDecoration(labelText: l10n.invoiceRef),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _rows.length; i++) _rowEditor(i, products),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addLine),
                  onPressed: () => setState(() => _rows.add(_PurchaseRow())),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${l10n.total}: ${formatTaka(total)}',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.titleMedium,
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
          onPressed: items == null ? null : () => _save(items),
          child: Text(l10n.save),
        ),
      ],
    );
  }

  Widget _rowEditor(int index, List<Product> products) {
    final l10n = AppLocalizations.of(context);
    final row = _rows[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              initialValue: row.productId,
              decoration: InputDecoration(labelText: l10n.product),
              items: [
                for (final p in products)
                  DropdownMenuItem(value: p.id, child: Text(p.name)),
              ],
              onChanged: (v) => setState(() => row.productId = v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: row.qty,
              decoration: InputDecoration(labelText: l10n.quantity),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: row.cost,
              decoration: InputDecoration(labelText: l10n.unitCost),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: row.expiry,
              decoration: InputDecoration(labelText: l10n.expiry),
              onChanged: (_) => setState(() {}),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _rows.length == 1
                ? null
                : () => setState(() => _rows.removeAt(index).dispose()),
          ),
        ],
      ),
    );
  }

  Future<void> _addSupplier(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.addSupplier),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.supplierName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    final supplier = await ref
        .read(databaseProvider)
        .purchasesDao
        .insertSupplier(SuppliersCompanion.insert(name: name));
    setState(() => _supplierId = supplier.id);
  }

  Future<void> _save(List<PurchaseDraftItem> items) async {
    final navigator = Navigator.of(context);
    final invoiceRef = _invoiceRef.text.trim();
    await ref.read(databaseProvider).purchasesDao.createPurchase(
          supplierId: _supplierId,
          invoiceRef: invoiceRef.isEmpty ? null : invoiceRef,
          items: items,
        );
    if (mounted) navigator.pop();
  }
}
