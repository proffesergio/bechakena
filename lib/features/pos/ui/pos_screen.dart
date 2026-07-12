import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/brand.dart';
import '../../../app/product_visuals.dart';
import '../../../app/providers.dart';
import '../../../core/seed/demo_catalog.dart';
import '../../../core/db/database.dart';
import '../../../core/db/sale_draft.dart';
import '../../../core/format.dart';
import '../../../core/money.dart';
import '../../../core/printing/print_service.dart';
import '../../../core/printing/receipt.dart';
import '../../../core/qty.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/logic/session.dart';
import '../logic/cart_controller.dart';
import 'receipt_dialog.dart';

class _SearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final _searchQueryProvider =
    NotifierProvider<_SearchQuery, String>(_SearchQuery.new);

class _SelectedCategory extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

final _selectedCategoryProvider =
    NotifierProvider<_SelectedCategory, String?>(_SelectedCategory.new);

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Row(
      children: [
        Expanded(flex: 3, child: _ProductPane()),
        VerticalDivider(width: 1),
        SizedBox(width: 380, child: _CartPane()),
      ],
    );
  }
}

class _ProductPane extends ConsumerStatefulWidget {
  const _ProductPane();

  @override
  ConsumerState<_ProductPane> createState() => _ProductPaneState();
}

class _ProductPaneState extends ConsumerState<_ProductPane> {
  // Keeps focus so a USB scanner (keyboard wedge + Enter) works at any time.
  final _searchFocus = FocusNode();
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(_searchQueryProvider.notifier).set('');
    _searchFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final query = ref.watch(_searchQueryProvider).trim().toLowerCase();
    final selectedCategory = ref.watch(_selectedCategoryProvider);
    final products = ref.watch(productsProvider);
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.searchProducts,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (v) => ref.read(_searchQueryProvider.notifier).set(v),
            onSubmitted: (v) async {
              final db = ref.read(databaseProvider);
              final product = await db.productsDao.byBarcode(v.trim());
              if (product != null) {
                ref.read(cartProvider.notifier).addProduct(product);
              }
              _clearSearch();
            },
          ),
        ),
        if (categories.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(l10n.allCategories),
                    selected: selectedCategory == null,
                    onSelected: (_) =>
                        ref.read(_selectedCategoryProvider.notifier).set(null),
                  ),
                ),
                for (final cat in categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      avatar: CircleAvatar(
                        backgroundColor: colorFromHex(cat.colorHex,
                            fallback: Theme.of(context).colorScheme.primary),
                        radius: 6,
                      ),
                      label: Text(
                          locale == 'bn' && (cat.nameBn ?? '').isNotEmpty
                              ? cat.nameBn!
                              : cat.name),
                      selected: selectedCategory == cat.id,
                      onSelected: (_) => ref
                          .read(_selectedCategoryProvider.notifier)
                          .set(selectedCategory == cat.id ? null : cat.id),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: products.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (all) {
              final visible = all
                  .where((p) =>
                      selectedCategory == null ||
                      p.categoryId == selectedCategory)
                  .where((p) =>
                      query.isEmpty ||
                      p.name.toLowerCase().contains(query) ||
                      (p.nameBn ?? '').contains(query) ||
                      (p.barcode ?? '') == query)
                  .toList();
              if (all.isEmpty) {
                return _EmptyCatalog(message: l10n.noProducts);
              }
              if (visible.isEmpty) {
                return Center(child: Text(l10n.noProducts));
              }
              final categoryById = {for (final c in categories) c.id: c};
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 190,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.25,
                ),
                itemCount: visible.length,
                itemBuilder: (context, i) => _ProductCard(
                  product: visible[i],
                  category: categoryById[visible[i].categoryId],
                  onAdded: _clearSearch,
                )
                    .animate()
                    .fadeIn(
                        duration: 220.ms,
                        delay: Duration(milliseconds: 25 * (i % 12)))
                    .scaleXY(begin: 0.94, curve: Curves.easeOutBack),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// First-run empty state: offer the demo catalog.
class _EmptyCatalog extends ConsumerWidget {
  const _EmptyCatalog({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🛒', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.auto_awesome),
            label: Text(l10n.loadDemo),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final loaded = await seedDemoData(ref.read(databaseProvider));
              messenger.showSnackBar(SnackBar(
                  content:
                      Text(loaded ? l10n.demoLoaded : l10n.demoSkipped)));
            },
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard(
      {required this.product, this.category, required this.onAdded});

  final Product product;
  final Category? category;
  final VoidCallback onAdded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final stock = ref.watch(stockProvider(product.id));
    final displayName = locale == 'bn' && (product.nameBn ?? '').isNotEmpty
        ? product.nameBn!
        : product.name;
    final accent = colorFromHex(category?.colorHex,
        fallback: theme.colorScheme.primary);
    final emoji = productEmoji(product);
    final stockQty = stock.value;
    final low = stockQty != null && stockQty <= product.lowStockLevel;

    return Card(
      child: InkWell(
        onTap: () {
          ref.read(cartProvider.notifier).addProduct(product);
          onAdded();
        },
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.18),
                theme.colorScheme.surface,
              ],
            ),
            border: Border(top: BorderSide(color: accent, width: 3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    if (emoji != null)
                      Text(emoji, style: const TextStyle(fontSize: 28)),
                  ],
                ),
                const Spacer(),
                Text(formatTaka(product.salePrice, locale: locale),
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold, color: accent)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: low
                        ? theme.colorScheme.errorContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l10n.stockLabel(stockQty?.display ?? '…'),
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: low
                            ? theme.colorScheme.onErrorContainer
                            : theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartPane extends ConsumerWidget {
  const _CartPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final cart = ref.watch(cartProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(l10n.invoicePanel,
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                tooltip: l10n.manualItem,
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const _ManualItemDialog(),
                ),
                icon: const Icon(Icons.playlist_add),
              ),
              IconButton(
                tooltip: l10n.cancel,
                onPressed: cart.isEmpty
                    ? null
                    : () => ref.read(cartProvider.notifier).clear(),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: cart.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.emptyCart, textAlign: TextAlign.center),
                  ),
                )
              : ListView.builder(
                  itemCount: cart.lines.length,
                  itemBuilder: (context, i) {
                    final line = cart.lines[i];
                    return ListTile(
                      dense: true,
                      title: Text(line.name),
                      subtitle: Text(
                          '${formatTaka(line.unitPrice, locale: locale)} × ${line.qty.display}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => ref
                                .read(cartProvider.notifier)
                                .setQty(i, line.qty - Qty.fromCount(1)),
                          ),
                          Text(line.qty.display),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => ref
                                .read(cartProvider.notifier)
                                .setQty(i, line.qty + Qty.fromCount(1)),
                          ),
                          SizedBox(
                            width: 76,
                            child: Text(
                              formatTaka(line.lineTotal, locale: locale),
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
              _totalRow(context, l10n.subtotal,
                  formatTaka(cart.subtotal, locale: locale)),
              if (!cart.vat.isZero)
                _totalRow(
                    context, l10n.vat, formatTaka(cart.vat, locale: locale)),
              if (!cart.billDiscount.isZero)
                _totalRow(context, l10n.discount,
                    '-${formatTaka(cart.billDiscount, locale: locale)}'),
              const SizedBox(height: 4),
              _totalRow(
                  context, l10n.total, formatTaka(cart.total, locale: locale),
                  emphasize: true),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  icon: const Icon(Icons.payments),
                  label: Text(l10n.pay),
                  onPressed: cart.isEmpty
                      ? null
                      : () => showDialog<void>(
                            context: context,
                            builder: (_) => const CheckoutDialog(),
                          ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _totalRow(BuildContext context, String label, String value,
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
  const _ManualItemDialog();

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
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            ref.read(cartProvider.notifier).addManual(
                  name: _name.text.trim(),
                  price: Money.parse(_price.text),
                  qty: Qty.parse(_qty.text),
                );
            Navigator.of(context).pop();
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class CheckoutDialog extends ConsumerStatefulWidget {
  const CheckoutDialog({super.key});

  @override
  ConsumerState<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends ConsumerState<CheckoutDialog> {
  late final TextEditingController _cash;
  final _bkash = TextEditingController();
  final _nagad = TextEditingController();
  final _card = TextEditingController();
  String? _customerId;

  @override
  void initState() {
    super.initState();
    final total = ref.read(cartProvider).total;
    _cash = TextEditingController(text: total.asDecimalString);
  }

  @override
  void dispose() {
    _cash.dispose();
    _bkash.dispose();
    _nagad.dispose();
    _card.dispose();
    super.dispose();
  }

  /// Empty field = zero; invalid or negative = null (blocks confirm).
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
    final total = ref.watch(cartProvider).total;
    final customers = ref.watch(customersProvider).value ?? const <Customer>[];
    final tenders = _tenders;
    final tendered = tenders?.values
        .fold(Money.zero, (Money sum, Money amount) => sum + amount);
    final due = tendered != null && tendered < total
        ? total - tendered
        : Money.zero;
    final change = tendered != null && tendered > total
        ? tendered - total
        : Money.zero;
    final canConfirm =
        tendered != null && (tendered >= total || _customerId != null);

    return AlertDialog(
      title: Text(l10n.confirmSale),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(formatTaka(total, locale: locale),
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
                Text(
                  l10n.willBeDue(formatTaka(due, locale: locale)),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                )
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
          onPressed: canConfirm ? _finalize : null,
          child: Text(l10n.confirmSale),
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

  Future<void> _finalize() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    final l10n = AppLocalizations.of(context);
    final cartController = ref.read(cartProvider.notifier);
    final db = ref.read(databaseProvider);
    final tenders = _tenders!;
    final total = ref.read(cartProvider).total;
    final tendered =
        tenders.values.fold(Money.zero, (Money s, Money a) => s + a);
    final change = tendered > total ? tendered - total : Money.zero;

    final sale = await db.salesDao.finalizeSale(
      invoicePrefix: 'BK',
      staffId: ref.read(currentStaffProvider)?.id,
      customerId: _customerId,
      items: cartController.toDraftItems(),
      tenders: [
        for (final entry in tenders.entries)
          if (!entry.value.isZero)
            TenderDraft(method: entry.key, amount: entry.value),
      ],
    );
    cartController.clear();
    if (_customerId != null) {
      ref.invalidate(customerDueProvider(_customerId!));
    }

    // Assemble the printable receipt from settings + the finalized sale.
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
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.saleComplete(sale.invoiceNo))),
    );
    if (!rootContext.mounted) return;
    showDialog<void>(
      context: rootContext,
      builder: (_) => ReceiptDialog(text: text),
    );
  }
}
