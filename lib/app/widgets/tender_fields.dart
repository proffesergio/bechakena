import 'package:flutter/material.dart';
import '../../l10n/gen/app_localizations.dart';

/// Shared split-tender inputs; each checkout keeps its own validation and totals.
class TenderFields extends StatelessWidget {
  const TenderFields({super.key, required this.cash, required this.bkash,
    required this.nagad, required this.card, required this.onChanged});

  final TextEditingController cash, bkash, nagad, card;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fields = [(cash, l10n.cashLabel), (bkash, l10n.bkash),
      (nagad, l10n.nagad), (card, l10n.card)];
    return Column(children: [
      for (final (controller, label) in fields)
        Padding(padding: const EdgeInsets.only(bottom: 8), child: TextField(
          controller: controller,
          autofocus: controller == cash,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label),
          onChanged: (_) => onChanged(),
        )),
    ]);
  }
}
