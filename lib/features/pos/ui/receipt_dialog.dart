import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/printing/escpos.dart';
import '../../../core/printing/print_service.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Post-sale receipt preview with a Print button (LAN ESC/POS).
class ReceiptDialog extends ConsumerWidget {
  const ReceiptDialog({super.key, required this.text, this.kickDrawer = true});

  final String text;
  final bool kickDrawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.receiptTitle),
      content: Container(
        width: 340,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          child: SelectableText(
            text,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.print),
          label: Text(l10n.printReceipt),
          onPressed: () => _print(context, ref),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  Future<void> _print(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final settings = ref.read(databaseProvider).settingsDao;
    try {
      final host = await settings.getValue('printer.host');
      if (host == null || host.isEmpty) {
        throw StateError(l10n.printerHost);
      }
      final port = int.tryParse(await settings.getValue('printer.port') ?? '') ?? 9100;
      await printToNetwork(host, port, escPosBytes(text, kickDrawer: kickDrawer));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.printFailed('$e'))));
    }
  }
}
