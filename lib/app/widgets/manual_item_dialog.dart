import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../../core/money.dart';
import '../../core/qty.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../features/auth/logic/permissions.dart';
import '../../features/settings/ui/business_settings_status.dart';

/// Shared validated entry form; each feature supplies its own persistence action.
class ManualItemDialog extends ConsumerStatefulWidget {
  const ManualItemDialog({super.key, required this.onSave});

  final FutureOr<void> Function(String name, Money price, Qty qty) onSave;

  @override
  ConsumerState<ManualItemDialog> createState() => _ManualItemDialogState();
}

class _ManualItemDialogState extends ConsumerState<ManualItemDialog> {
  bool _saving = false;
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
                    final price = Money.parse(v ?? '', currency: ref.read(shopCurrencyProvider));
                    if (price.isNegative) return l10n.invalidAmount;
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
                    final qty = Qty.parse(v ?? '');
                    if (qty <= Qty.zero) return l10n.invalidAmount;
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
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : () async {
            if (!_formKey.currentState!.validate()) return;
            if (!ref.read(canProvider(Capability.sell))) return;
            final navigator = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);
            setState(() => _saving = true);
            try {
              await widget.onSave(_name.text.trim(),
                Money.parse(_price.text, currency: ref.read(shopCurrencyProvider)),
                Qty.parse(_qty.text));
              if (mounted) navigator.pop();
            } catch (error) {
              if (mounted) {
                setState(() => _saving = false);
                messenger.showSnackBar(SnackBar(content: Text(l10n.saveFailed('$error'))));
              }
            }
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
