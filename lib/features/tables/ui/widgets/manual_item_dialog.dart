import '../../../settings/ui/business_settings_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/money.dart';
import '../../../../core/qty.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// Off-menu item for a running order: name, price, qty — persisted straight
/// to the order so the tab survives navigation.
class ManualItemDialog extends ConsumerStatefulWidget {
  const ManualItemDialog({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<ManualItemDialog> createState() => _ManualItemDialogState();
}

class _ManualItemDialogState extends ConsumerState<ManualItemDialog> {
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
    final settingsStatus = businessSettingsStatus(ref, context);
    if (settingsStatus != null) return settingsStatus;
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
                    Money.parse(v ?? '', currency: ref.read(shopCurrencyProvider));
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
                  price: Money.parse(_price.text, currency: ref.read(shopCurrencyProvider)),
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
