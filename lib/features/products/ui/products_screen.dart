import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../../../core/format.dart';
import '../../../core/money.dart';
import '../../../core/qty.dart';
import '../../../l10n/gen/app_localizations.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final products = ref.watch(productsProvider);

    return Scaffold(
      body: products.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) => all.isEmpty
            ? Center(child: Text(l10n.noProducts))
            : ListView.separated(
                itemCount: all.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final p = all[i];
                  final stock = ref.watch(stockProvider(p.id));
                  return ListTile(
                    title: Text(p.name),
                    subtitle:
                        Text(l10n.stockLabel(stock.value?.display ?? '…')),
                    trailing: Text(
                      formatTaka(p.salePrice, locale: locale),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (_) => AdjustStockDialog(product: p),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l10n.addProduct),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const AddProductDialog(),
        ),
      ),
    );
  }
}

/// Manual stock correction: shrinkage, count fixes, returns to supplier.
/// Writes an append-only adjustment movement — never edits a stock number.
class AdjustStockDialog extends ConsumerStatefulWidget {
  const AdjustStockDialog({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends ConsumerState<AdjustStockDialog> {
  final _delta = TextEditingController();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _delta.dispose();
    _reason.dispose();
    super.dispose();
  }

  Qty? get _deltaQty {
    try {
      final q = Qty.parse(_delta.text);
      return q.isZero ? null : q;
    } on FormatException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stock = ref.watch(stockProvider(widget.product.id));
    final delta = _deltaQty;

    return AlertDialog(
      title: Text('${l10n.adjustStock} — ${widget.product.name}'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.currentStock(stock.value?.display ?? '…')),
            const SizedBox(height: 12),
            TextField(
              controller: _delta,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.qtyChange,
                errorText:
                    _delta.text.isNotEmpty && delta == null ? l10n.invalidAmount : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reason,
              decoration: InputDecoration(labelText: l10n.reason),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: delta == null
              ? null
              : () async {
                  final navigator = Navigator.of(context);
                  final reason = _reason.text.trim();
                  await ref.read(databaseProvider).stockDao.addMovement(
                        productId: widget.product.id,
                        qtyDelta: delta,
                        type: MovementType.adjustment,
                        note: reason.isEmpty ? null : reason,
                      );
                  if (mounted) navigator.pop();
                },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class AddProductDialog extends ConsumerStatefulWidget {
  const AddProductDialog({super.key});

  @override
  ConsumerState<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _barcode = TextEditingController();
  final _openingStock = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _barcode.dispose();
    _openingStock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.addProduct),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 360,
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
                  if (v == null || v.trim().isEmpty) return l10n.requiredField;
                  try {
                    Money.parse(v);
                    return null;
                  } on FormatException {
                    return l10n.invalidAmount;
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _barcode,
                decoration: InputDecoration(labelText: l10n.barcode),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _openingStock,
                decoration: InputDecoration(labelText: l10n.openingStock),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  try {
                    Qty.parse(v);
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
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final db = ref.read(databaseProvider);

    final barcode = _barcode.text.trim();
    final product = await db.productsDao.insertProduct(ProductsCompanion.insert(
      name: _name.text.trim(),
      salePrice: Money.parse(_price.text),
      barcode: Value(barcode.isEmpty ? null : barcode),
    ));

    final openingText = _openingStock.text.trim();
    if (openingText.isNotEmpty) {
      final opening = Qty.parse(openingText);
      if (!opening.isZero) {
        await db.stockDao.addMovement(
          productId: product.id,
          qtyDelta: opening,
          type: MovementType.adjustment,
        );
      }
    }
    if (mounted) navigator.pop();
  }
}
