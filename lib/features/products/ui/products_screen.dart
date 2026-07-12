import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../app/product_visuals.dart';
import '../../../app/providers.dart';
import '../../../core/csv/product_csv.dart';
import '../../../core/db/database.dart';
import '../../../core/format.dart';
import '../../../core/money.dart';
import '../../../core/qty.dart';
import '../../../l10n/gen/app_localizations.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _search = TextEditingController();
  String? _categoryId;
  bool _lowStockOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _filtered =>
      _search.text.trim().isNotEmpty || _categoryId != null || _lowStockOnly;

  List<Product> _applyFilters(List<Product> all, Set<String> lowStockIds) {
    final q = _search.text.trim().toLowerCase();
    return [
      for (final pr in all)
        if ((_categoryId == null || pr.categoryId == _categoryId) &&
            (!_lowStockOnly || lowStockIds.contains(pr.id)) &&
            (q.isEmpty ||
                pr.name.toLowerCase().contains(q) ||
                (pr.nameBn?.toLowerCase().contains(q) ?? false) ||
                (pr.barcode?.toLowerCase().contains(q) ?? false) ||
                (pr.sku?.toLowerCase().contains(q) ?? false)))
          pr,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final products = ref.watch(productsProvider);
    final lowStockIds = _lowStockOnly
        ? (ref.watch(lowStockProvider).value ?? const <LowStockRow>[])
            .map((r) => r.product.id)
            .toSet()
        : const <String>{};

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navProducts),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.upload_file),
            label: Text(l10n.importCsv),
            onPressed: () => _importCsv(context, ref),
          ),
          TextButton.icon(
            icon: const Icon(Icons.download),
            label: Text(l10n.exportCsv),
            onPressed: () => _exportCsv(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(
            controller: _search,
            categoryId: _categoryId,
            lowStockOnly: _lowStockOnly,
            showClear: _filtered,
            onSearch: () => setState(() {}),
            onCategory: (id) => setState(() => _categoryId = id),
            onLowStock: (v) => setState(() => _lowStockOnly = v),
            onClear: () => setState(() {
              _search.clear();
              _categoryId = null;
              _lowStockOnly = false;
            }),
          ),
          const Divider(height: 1),
          Expanded(
            child: products.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (all) {
                final list = _applyFilters(all, lowStockIds);
                if (all.isEmpty) return Center(child: Text(l10n.noProducts));
                if (list.isEmpty) {
                  return Center(child: Text(l10n.noResults));
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) =>
                      _ProductTile(product: list[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l10n.addProduct),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const ProductEditDialog(),
        ),
      ),
    );
  }

  Future<void> _importCsv(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final file = await openFile(acceptedTypeGroups: [
      const XTypeGroup(label: 'CSV', extensions: ['csv']),
    ]);
    if (file == null) return;
    final result = parseProductRows(await file.readAsString());
    final db = ref.read(databaseProvider);
    for (final pr in result.products) {
      final product = await db.productsDao.insertProduct(ProductsCompanion.insert(
        name: pr.name,
        nameBn: Value(pr.nameBn),
        barcode: Value(pr.barcode),
        unit: Value(pr.unit),
        salePrice: pr.salePrice,
        vatRateBp: Value(pr.vatRateBp),
      ));
      if (!pr.openingStock.isZero) {
        await db.stockDao.addMovement(
          productId: product.id,
          qtyDelta: pr.openingStock,
          type: MovementType.adjustment,
          note: 'csv import',
        );
      }
    }
    final msg = result.errors.isEmpty
        ? l10n.importDone('${result.products.length}')
        : '${l10n.importDone('${result.products.length}')} · '
            '${l10n.importErrors('${result.errors.length}')}';
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final db = ref.read(databaseProvider);
    final products = await db.productsDao.watchActive().first;
    final rows = <ProductCsvRow>[];
    for (final pr in products) {
      final stock = await db.stockDao.stockFor(pr.id);
      rows.add(ProductCsvRow(
        name: pr.name,
        nameBn: pr.nameBn,
        barcode: pr.barcode,
        unit: pr.unit,
        salePrice: pr.salePrice,
        vatRateBp: pr.vatRateBp,
        openingStock: stock,
      ));
    }
    final location = await getSaveLocation(suggestedName: 'products.csv');
    if (location == null) return;
    await File(location.path).writeAsString(productsToCsv(rows));
    messenger.showSnackBar(
        SnackBar(content: Text(l10n.exportDone(location.path))));
  }
}

/// Search + category + low-stock filter row above the product list.
class _FilterBar extends ConsumerWidget {
  const _FilterBar({
    required this.controller,
    required this.categoryId,
    required this.lowStockOnly,
    required this.showClear,
    required this.onSearch,
    required this.onCategory,
    required this.onLowStock,
    required this.onClear,
  });

  final TextEditingController controller;
  final String? categoryId;
  final bool lowStockOnly;
  final bool showClear;
  final VoidCallback onSearch;
  final ValueChanged<String?> onCategory;
  final ValueChanged<bool> onLowStock;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 260,
            child: TextField(
              controller: controller,
              onChanged: (_) => onSearch(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.searchProducts,
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<String?>(
              initialValue: categoryId,
              isDense: true,
              decoration: InputDecoration(labelText: l10n.category),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.allCategories)),
                for (final c in categories)
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: onCategory,
            ),
          ),
          FilterChip(
            label: Text(l10n.lowStockOnly),
            selected: lowStockOnly,
            onSelected: onLowStock,
          ),
          if (showClear)
            TextButton.icon(
              icon: const Icon(Icons.clear),
              label: Text(l10n.clearFilters),
              onPressed: onClear,
            ),
        ],
      ),
    );
  }
}

/// One product row: photo, name, stock/category, price, and an actions menu
/// (Edit · Adjust stock · Delete).
class _ProductTile extends ConsumerWidget {
  const _ProductTile({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final stock = ref.watch(stockProvider(product.id));
    return ListTile(
      leading: _ProductThumb(product: product),
      title: Text(product.name),
      subtitle: Text(l10n.stockLabel(stock.value?.display ?? '…')),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatTaka(product.salePrice, locale: locale),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          PopupMenuButton<String>(
            onSelected: (value) => switch (value) {
              'edit' => showDialog<void>(
                  context: context,
                  builder: (_) => ProductEditDialog(product: product),
                ),
              'stock' => showDialog<void>(
                  context: context,
                  builder: (_) => AdjustStockDialog(product: product),
                ),
              'delete' => _confirmDelete(context, ref),
              _ => null,
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                    leading: const Icon(Icons.edit),
                    title: Text(l10n.editProduct)),
              ),
              PopupMenuItem(
                value: 'stock',
                child: ListTile(
                    leading: const Icon(Icons.tune),
                    title: Text(l10n.adjustStock)),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                    leading: Icon(Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error),
                    title: Text(l10n.deleteProduct)),
              ),
            ],
          ),
        ],
      ),
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => ProductEditDialog(product: product),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l10n.deleteProduct),
        content: Text(l10n.deleteProductConfirm(product.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dctx).pop(false),
              child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dctx).colorScheme.error),
            onPressed: () => Navigator.of(dctx).pop(true),
            child: Text(l10n.deleteProduct),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(databaseProvider).productsDao.softDelete(product.id);
    messenger.showSnackBar(SnackBar(content: Text(l10n.productDeleted)));
  }
}

/// Product art: real photo, emoji glyph (`emoji:🍎`), or a fallback icon.
class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    const size = 44.0;
    final emoji = productEmoji(product);
    final path = product.imagePath;
    final hasPhoto = emoji == null &&
        path != null &&
        path.isNotEmpty &&
        !path.startsWith('emoji:') &&
        File(path).existsSync();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? Image.file(File(path),
              key: ValueKey(path), fit: BoxFit.cover, width: size, height: size)
          : emoji != null
              ? Text(emoji, style: TextStyle(fontSize: size * 0.5))
              : const Icon(Icons.inventory_2_outlined),
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

/// Add a new product, or edit an existing one when [product] is non-null.
/// Covers name (+Bengali), barcode, SKU, unit, price, cost, category, low-stock
/// level and photo. Opening stock is only offered when adding.
class ProductEditDialog extends ConsumerStatefulWidget {
  const ProductEditDialog({super.key, this.product});

  final Product? product;

  @override
  ConsumerState<ProductEditDialog> createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends ConsumerState<ProductEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _nameBn;
  late final TextEditingController _price;
  late final TextEditingController _cost;
  late final TextEditingController _barcode;
  late final TextEditingController _sku;
  late final TextEditingController _unit;
  late final TextEditingController _lowStock;
  final _openingStock = TextEditingController();
  String? _categoryId;
  String? _imagePath;
  bool _saving = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final pr = widget.product;
    _name = TextEditingController(text: pr?.name ?? '');
    _nameBn = TextEditingController(text: pr?.nameBn ?? '');
    _price = TextEditingController(
        text: pr == null ? '' : pr.salePrice.asDecimalString);
    _cost = TextEditingController(
        text: pr == null || pr.costPrice.isZero
            ? ''
            : pr.costPrice.asDecimalString);
    _barcode = TextEditingController(text: pr?.barcode ?? '');
    _sku = TextEditingController(text: pr?.sku ?? '');
    _unit = TextEditingController(text: pr?.unit ?? 'pcs');
    _lowStock = TextEditingController(
        text: pr == null || pr.lowStockLevel.isZero
            ? ''
            : pr.lowStockLevel.display);
    _categoryId = pr?.categoryId;
    // Keep an emoji glyph as-is; only real photo paths are editable here.
    final path = pr?.imagePath;
    _imagePath = (path != null && !path.startsWith('emoji:')) ? path : null;
  }

  @override
  void dispose() {
    _name.dispose();
    _nameBn.dispose();
    _price.dispose();
    _cost.dispose();
    _barcode.dispose();
    _sku.dispose();
    _unit.dispose();
    _lowStock.dispose();
    _openingStock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
    return AlertDialog(
      title: Text(_isEdit ? l10n.editProduct : l10n.addProduct),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _imageRow(context, l10n),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  autofocus: !_isEdit,
                  decoration: InputDecoration(labelText: l10n.productName),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.requiredField
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameBn,
                  decoration: InputDecoration(labelText: l10n.productNameBn),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _moneyField(_price, l10n.price, required: true, l10n: l10n)),
                    const SizedBox(width: 12),
                    Expanded(child: _moneyField(_cost, l10n.costPrice, required: false, l10n: l10n)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _unit,
                        decoration: InputDecoration(labelText: l10n.unit),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _qtyField(_lowStock, l10n.lowStockLevel, l10n)),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _categoryId,
                  decoration: InputDecoration(labelText: l10n.category),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.noCategory)),
                    for (final c in categories)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _barcode,
                  decoration: InputDecoration(labelText: l10n.barcode),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sku,
                  decoration: InputDecoration(labelText: l10n.sku),
                ),
                if (!_isEdit) ...[
                  const SizedBox(height: 12),
                  _qtyField(_openingStock, l10n.openingStock, l10n),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }

  Widget _moneyField(TextEditingController c, String label,
          {required bool required, required AppLocalizations l10n}) =>
      TextFormField(
        controller: c,
        decoration: InputDecoration(labelText: label),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (v) {
          final text = v?.trim() ?? '';
          if (text.isEmpty) return required ? l10n.requiredField : null;
          try {
            Money.parse(text);
            return null;
          } on FormatException {
            return l10n.invalidAmount;
          }
        },
      );

  Widget _qtyField(TextEditingController c, String label, AppLocalizations l10n) =>
      TextFormField(
        controller: c,
        decoration: InputDecoration(labelText: label),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (v) {
          final text = v?.trim() ?? '';
          if (text.isEmpty) return null;
          try {
            Qty.parse(text);
            return null;
          } on FormatException {
            return l10n.invalidAmount;
          }
        },
      );

  Widget _imageRow(BuildContext context, AppLocalizations l10n) {
    final hasPhoto = _imagePath != null &&
        _imagePath!.isNotEmpty &&
        File(_imagePath!).existsSync();
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: hasPhoto
              ? Image.file(File(_imagePath!),
                  key: ValueKey(_imagePath), fit: BoxFit.cover)
              : const Icon(Icons.image_outlined),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(l10n.productImage,
              style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.upload),
          label: Text(l10n.chooseImage),
          onPressed: _pickImage,
        ),
        if (hasPhoto)
          IconButton(
            tooltip: l10n.removeImage,
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _imagePath = null),
          ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picked = await openFile(acceptedTypeGroups: [
      const XTypeGroup(
          label: 'Image', extensions: ['png', 'jpg', 'jpeg', 'bmp', 'webp']),
    ]);
    if (picked == null) return;
    final dir = await getApplicationSupportDirectory();
    final dest = File(
        p.join(dir.path, 'product_${DateTime.now().microsecondsSinceEpoch}.img'));
    await picked.saveTo(dest.path);
    if (mounted) setState(() => _imagePath = dest.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final db = ref.read(databaseProvider);

    String? clean(TextEditingController c) {
      final t = c.text.trim();
      return t.isEmpty ? null : t;
    }

    final cost =
        _cost.text.trim().isEmpty ? Money.zero : Money.parse(_cost.text);
    final low = _lowStock.text.trim().isEmpty
        ? Qty.zero
        : Qty.parse(_lowStock.text);
    final unit = _unit.text.trim().isEmpty ? 'pcs' : _unit.text.trim();

    if (_isEdit) {
      final updated = widget.product!.copyWith(
        name: _name.text.trim(),
        nameBn: Value(clean(_nameBn)),
        salePrice: Money.parse(_price.text),
        costPrice: cost,
        barcode: Value(clean(_barcode)),
        sku: Value(clean(_sku)),
        unit: unit,
        categoryId: Value(_categoryId),
        lowStockLevel: low,
        imagePath: Value(_imagePath),
      );
      await db.productsDao.updateProduct(updated);
    } else {
      final product =
          await db.productsDao.insertProduct(ProductsCompanion.insert(
        name: _name.text.trim(),
        nameBn: Value(clean(_nameBn)),
        salePrice: Money.parse(_price.text),
        costPrice: Value(cost),
        barcode: Value(clean(_barcode)),
        sku: Value(clean(_sku)),
        unit: Value(unit),
        categoryId: Value(_categoryId),
        lowStockLevel: Value(low),
        imagePath: Value(_imagePath),
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
    }
    if (mounted) navigator.pop();
  }
}
