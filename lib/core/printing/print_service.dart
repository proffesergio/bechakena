import '../db/database.dart';
import '../money.dart';
import '../platform/files.dart';
import 'escpos.dart';
import 'logo_raster.dart';
import 'printer_transport.dart';
import 'receipt.dart';
import 'text_raster.dart';

/// Sends raw ESC/POS bytes to a LAN thermal printer (RAW/JetDirect, port 9100).
/// Used by the LAN transport; USB/Bluetooth go through [PrinterBackend].
/// Implementation is platform-split: real sockets on native, a clear
/// "desktop-only" error in the browser demo.
export '../platform/lan_print.dart' show printToNetwork;

/// Encodes [text] into ESC/POS bytes, prepending the shop logo raster (if one
/// is configured and decodable) sized for [widthDots]. A missing or broken
/// logo file is skipped silently — it must never block a receipt.
Future<List<int>> composeReceiptBytes({
  required SettingsDao settings,
  required String text,
  required int widthDots,
  bool kickDrawer = false,
}) async {
  List<int>? raster;
  final logoPath = await settings.getValue('shop.logoPath');
  if (logoPath != null && logoPath.isNotEmpty) {
    final logoBytes = await readLocalFileBytes(logoPath);
    if (logoBytes != null) {
      try {
        raster = tryEscPosRasterFromImage(logoBytes, maxWidthDots: widthDots);
      } catch (_) {
        raster = null;
      }
    }
  }
  final body = await receiptTextBody(text, widthDots: widthDots);
  return escPosBytes(
    text,
    kickDrawer: kickDrawer,
    rasterHeader: raster,
    encodedBody: body,
  );
}

/// Composes the receipt (with logo) and prints it over the configured
/// transport. Throws [PrinterUnavailable] when the transport isn't ready.
Future<void> printReceiptText(
  SettingsDao settings,
  String text, {
  bool kickDrawer = false,
}) async {
  final cfg = await loadPrinterConfig(settings);
  final bytes = await composeReceiptBytes(
    settings: settings,
    text: text,
    widthDots: cfg.widthDots,
    kickDrawer: kickDrawer,
  );
  await sendToPrinter(cfg, bytes);
}

/// Maps a finalized sale + its items to printable receipt data.
ReceiptData receiptFromSale({
  required Sale sale,
  required List<SaleItem> items,
  required String shopName,
  String? address,
  String? phone,
  String? footer,
  Money change = Money.zero,
}) {
  return ReceiptData(
    shopName: shopName,
    address: address,
    phone: phone,
    invoiceNo: sale.invoiceNo,
    dateTime: sale.createdAt,
    items: [
      for (final item in items)
        ReceiptItem(
          name: item.nameSnapshot,
          qty: item.qty,
          unitPrice: item.unitPrice,
          lineTotal: item.lineTotal,
        ),
    ],
    subtotal: sale.subtotal,
    discount: sale.discount,
    vat: sale.vat,
    total: sale.total,
    paid: sale.paid,
    due: sale.due,
    change: change,
    footer: footer,
  );
}
