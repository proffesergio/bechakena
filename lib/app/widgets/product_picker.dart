import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/format.dart';
import '../../l10n/gen/app_localizations.dart';
import '../product_visuals.dart';
import '../providers.dart';

/// Search text for the product grid (shared by POS and restaurant order editor).
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

/// Search box + category chips + animated product/menu grid. Emits the tapped
/// product via [onPick]; the flagship POS routes that into the cart and the
/// restaurant editor routes it into the running order — one grid, two hosts.
class ProductPicker extends ConsumerStatefulWidget {
  const ProductPicker({super.key, required this.onPick, this.emptyBuilder});

  final void Function(Product product) onPick;

  /// Rendered when the (scoped) catalog is completely empty. POS offers the
  /// demo-load button here; other hosts can pass a simple hint.
  final WidgetBuilder? emptyBuilder;

  @override
  ConsumerState<ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends ConsumerState<ProductPicker> {
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

  void _pick(Product product) {
    widget.onPick(product);
    _clearSearch();
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
              if (product != null) widget.onPick(product);
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
                      label: Text(locale == 'bn' && (cat.nameBn ?? '').isNotEmpty
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
                return widget.emptyBuilder?.call(context) ??
                    Center(child: Text(l10n.noProducts));
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
                itemBuilder: (context, i) => ProductCard(
                  product: visible[i],
                  category: categoryById[visible[i].categoryId],
                  onTap: () => _pick(visible[i]),
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

/// A single catalog card — category-accented, emoji art, live stock badge.
class ProductCard extends ConsumerWidget {
  const ProductCard(
      {super.key, required this.product, this.category, required this.onTap});

  final Product product;
  final Category? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final stock = ref.watch(stockProvider(product.id));
    final displayName = locale == 'bn' && (product.nameBn ?? '').isNotEmpty
        ? product.nameBn!
        : product.name;
    final accent =
        colorFromHex(category?.colorHex, fallback: theme.colorScheme.primary);
    final emoji = productEmoji(product);
    final stockQty = stock.value;
    final low = stockQty != null && stockQty <= product.lowStockLevel;

    return Card(
      child: InkWell(
        onTap: onTap,
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
