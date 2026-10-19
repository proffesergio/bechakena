import '../../../auth/logic/permissions.dart';
import '../../../settings/data/business_settings.dart';
import '../../../settings/ui/business_settings_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/brand.dart';
import '../../../../app/providers.dart';
import '../../../../core/db/database.dart';
import '../../../../core/db/sale_draft.dart';
import '../../../../core/format.dart';
import '../../../../core/money.dart';
import '../../../../core/printing/print_service.dart';
import '../../../../core/printing/receipt.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../auth/logic/access.dart';
import '../../../auth/logic/session.dart';
import '../../logic/cart_controller.dart';
import '../receipt_dialog.dart';

/// Tender + customer dialog. Splits the payment across cash/bKash/Nagad/card,
/// allows a baki (due) sale for a selected customer, finalizes the immutable
/// sale row and shows the printable receipt.
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
      final m = Money.parse(text, currency: ref.read(shopCurrencyProvider));
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
    final settingsStatus = businessSettingsStatus(ref, context);
    if (settingsStatus != null) return settingsStatus;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final total = ref.watch(cartProvider).total;
    final customers =
        ref.watch(scopedCustomersProvider).value ?? const <Customer>[];
    final tenders = _tenders;
    final tendered = tenders?.values.fold(
      Money.zero,
      (Money sum, Money amount) => sum + amount,
    );
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
              Text(
                formatTaka(
                  total,
                  locale: locale,
                  currency: ref.read(shopCurrencyProvider),
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _customerId,
                decoration: InputDecoration(labelText: l10n.customerLabel),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.walkIn),
                  ),
                  for (final c in customers)
                    DropdownMenuItem<String?>(value: c.id, child: Text(c.name)),
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
                Text(
                  l10n.invalidAmount,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                )
              else if (!due.isZero)
                Text(
                  l10n.willBeDue(
                    formatTaka(
                      due,
                      locale: locale,
                      currency: ref.read(shopCurrencyProvider),
                    ),
                  ),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                )
              else
                Text(
                  '${l10n.change}: ${formatTaka(change, locale: locale, currency: ref.read(shopCurrencyProvider))}',
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
          onPressed: canConfirm ? _finalize : null,
          child: Text(l10n.confirmSale),
        ),
      ],
    );
  }

  Widget _tenderField(
    TextEditingController controller,
    String label, {
    bool autofocus = false,
  }) {
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
    if (!ref.read(canProvider(Capability.sell))) return;
    if (_customerId != null &&
        !ref.read(canManageCustomerProvider(_customerId!)))
      return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    final l10n = AppLocalizations.of(context);
    final cartController = ref.read(cartProvider.notifier);
    final db = ref.read(databaseProvider);
    final tenders = _tenders!;
    final total = ref.read(cartProvider).total;
    final tendered = tenders.values.fold(
      Money.zero,
      (Money s, Money a) => s + a,
    );
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
    final business = await BusinessSettingsStore(db).load();
    final receipt = receiptFromSale(
      business: business,
      sale: sale,
      items: items,
      shopName: await settings.getValue('shop.name') ?? Brand.name,
      address: await settings.getValue('shop.address'),
      phone: await settings.getValue('shop.phone'),
      footer:
          await settings.getValue('receipt.footer') ??
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
      builder: (_) => ReceiptDialog(text: text, invoiceNo: sale.invoiceNo),
    );
  }
}
