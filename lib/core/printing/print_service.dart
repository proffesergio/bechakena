import 'dart:io';

import '../db/database.dart';
import '../money.dart';
import 'escpos.dart';
import 'logo_raster.dart';
import 'printer_transport.dart';
import 'receipt.dart';

/// Sends raw ESC/POS bytes to a LAN thermal printer (RAW/JetDirect, port 9100).
/// Used by the LAN transport; USB/Bluetooth go through [PrinterBackend].
Future<void> printToNetwork(String host, int port, List<int> bytes) async {
  final socket = await Socket.connect(host, port,
      timeout: const Duration(seconds: 5));
  try {
    socket.add(bytes);
    await socket.flush();
  } finally {
    await socket.close();
  }
}

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
    final file = File(logoPath);
    if (await file.exists()) {
      try {
        raster = tryEscPosRasterFromImage(await file.readAsBytes(),
            maxWidthDots: widthDots);
      } catch (_) {
        raster = null;
      }
    }
  }
  return escPosBytes(text, kickDrawer: kickDrawer, rasterHeader: raster);
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
