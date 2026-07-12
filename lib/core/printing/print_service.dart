import 'dart:io';

import '../db/database.dart';
import '../money.dart';
import 'receipt.dart';

/// Sends raw ESC/POS bytes to a LAN thermal printer (RAW/JetDirect, port 9100).
/// USB (Windows) and Bluetooth (Android) transports arrive next.
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
