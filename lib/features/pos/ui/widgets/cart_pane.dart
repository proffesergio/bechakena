import '../../../settings/ui/business_settings_status.dart';
import '../../../../app/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format.dart';
import '../../../../core/qty.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../logic/cart_controller.dart';
import 'checkout_dialog.dart';
import '../../../../app/widgets/manual_item_dialog.dart';

/// The right-hand invoice pane: current cart lines, totals and the pay button.
class CartPane extends ConsumerWidget {
  const CartPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsStatus = businessSettingsStatus(ref, context);
    if (settingsStatus != null) return settingsStatus;
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
                  builder: (_) => ManualItemDialog(onSave: (name, price, qty) {
                    ref.read(cartProvider.notifier).addManual(name: name, price: price, qty: qty);
                  }),
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
                          '${formatTaka(line.unitPrice, locale: locale, currency: ref.read(shopCurrencyProvider))} × ${line.qty.display}'),
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
                              formatTaka(line.lineTotal, locale: locale, currency: ref.read(shopCurrencyProvider)),
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
                  formatTaka(cart.subtotal, locale: locale, currency: ref.read(shopCurrencyProvider))),
              if (!cart.vat.isZero)
                _totalRow(
                    context, ref.watch(businessSettingsProvider).requireValue.taxLabel, formatTaka(cart.vat, locale: locale, currency: ref.read(shopCurrencyProvider))),
              if (!cart.billDiscount.isZero)
                _totalRow(context, l10n.discount,
                    '-${formatTaka(cart.billDiscount, locale: locale, currency: ref.read(shopCurrencyProvider))}'),
              const SizedBox(height: 4),
              _totalRow(
                  context, l10n.total, formatTaka(cart.total, locale: locale, currency: ref.read(shopCurrencyProvider)),
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
