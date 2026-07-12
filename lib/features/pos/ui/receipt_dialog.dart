import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/printing/invoice_export.dart';
import '../../../core/printing/print_service.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Post-sale receipt preview. Prints over ESC/POS when a printer is set up, and
/// can always save a soft copy (PDF/image) to local storage — the fallback for
/// shops running without a printer connected.
class ReceiptDialog extends ConsumerStatefulWidget {
  const ReceiptDialog({
    super.key,
    required this.text,
    this.invoiceNo = '',
    this.kickDrawer = true,
  });

  final String text;
  final String invoiceNo;
  final bool kickDrawer;

  @override
  ConsumerState<ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends ConsumerState<ReceiptDialog> {
  // Wraps the on-screen receipt so it can be rasterised for PNG/PDF export.
  final _boundaryKey = GlobalKey();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.receiptTitle),
      content: RepaintBoundary(
        key: _boundaryKey,
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // Solid surface (not surfaceContainerHighest) so the captured PNG
            // has a clean, printable background in either theme.
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              widget.text,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.print),
          label: Text(l10n.printReceipt),
          onPressed: _saving ? null : () => _print(context),
        ),
        MenuAnchor(
          builder: (context, controller, _) => TextButton.icon(
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_alt),
            label: Text(l10n.saveInvoice),
            onPressed: _saving
                ? null
                : () => controller.isOpen
                    ? controller.close()
                    : controller.open(),
          ),
          menuChildren: [
            MenuItemButton(
              leadingIcon: const Icon(Icons.picture_as_pdf),
              onPressed: () => _save(context, asPdf: true),
              child: Text(l10n.saveAsPdf),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.image),
              onPressed: () => _save(context, asPdf: false),
              child: Text(l10n.saveAsImage),
            ),
          ],
        ),
        FilledButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  Future<void> _print(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final settings = ref.read(databaseProvider).settingsDao;
    try {
      await printReceiptText(settings, widget.text,
          kickDrawer: widget.kickDrawer);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.printFailed('$e'))));
    }
  }

  Future<void> _save(BuildContext context, {required bool asPdf}) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final png = await captureInvoicePng(_boundaryKey);
      final path = asPdf
          ? await saveInvoicePdf(png, invoiceNo: widget.invoiceNo)
          : await saveInvoicePng(png, invoiceNo: widget.invoiceNo);
      messenger.showSnackBar(SnackBar(content: Text(l10n.invoiceSaved(path))));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.saveFailed('$e'))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
