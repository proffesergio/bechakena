import 'package:bechakena/core/money.dart';
import 'package:bechakena/core/printing/escpos.dart';
import 'package:bechakena/core/printing/kot.dart';
import 'package:bechakena/core/printing/receipt.dart';
import 'package:bechakena/core/printing/text_raster.dart';
import 'package:bechakena/core/qty.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ASCII body and printer control bytes stay identical', () async {
    const text = 'SHOP\nRice             Tk 20.00\nTOTAL            Tk 20.00';
    final body = await receiptTextBody(text, widthDots: 384);
    expect(body, text.codeUnits);
    final bytes = escPosBytes(text, kickDrawer: true, encodedBody: body);
    expect(bytes, escPosBytes(text, kickDrawer: true));
    expect(bytes.take(7), [0x1b, 0x40, 0x1b, 0x70, 0, 0x19, 0xfa]);
    expect(bytes.sublist(bytes.length - 4), [0x1d, 0x56, 0x42, 0]);
  });

  for (final width in [384, 576]) {
    testWidgets('Bangla shapes visible pixels within $width dots', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final body = await receiptTextBody(
          List.filled(12, 'বাংলা চাল এবং মিষ্টি দই').join(' '),
          widthDots: width,
        );
        var offset = 0;
        var chunks = 0;
        var ink = 0;
        while (offset < body.length) {
          expect(body.sublist(offset, offset + 4), [0x1d, 0x76, 0x30, 0]);
          final rowBytes = body[offset + 4] + body[offset + 5] * 256;
          final rows = body[offset + 6] + body[offset + 7] * 256;
          expect(rowBytes * 8, width);
          expect(rows, inInclusiveRange(1, 64));
          final end = offset + 8 + rowBytes * rows;
          ink += body.sublist(offset + 8, end).where((v) => v != 0).length;
          offset = end;
          chunks++;
        }
        expect(ink, greaterThan(100));
        expect(chunks, greaterThan(1));
        expect(offset, body.length);
      });
    });
  }

  test('receipt and KOT preserve long Bangla names and notes', () {
    final name = List.filled(8, 'মিষ্টি দই').join(' ');
    final receipt = renderReceiptText(
      ReceiptData(
        shopName: 'দোকান',
        invoiceNo: 'INV-1',
        dateTime: DateTime(2026),
        items: [
          ReceiptItem(
            name: name,
            qty: Qty(1000),
            unitPrice: Money.zero,
            lineTotal: Money.zero,
          ),
        ],
        subtotal: Money.zero,
        discount: Money.zero,
        vat: Money.zero,
        total: Money.zero,
        paid: Money.zero,
        due: Money.zero,
        change: Money.zero,
      ),
    );
    expect(receipt, contains(name));
    final kot = renderKotText(
      title: 'রান্নাঘর',
      orderLabel: 'টেবিল ১',
      at: DateTime(2026),
      items: [KotLine(name: name, qty: Qty(1000), note: name)],
    );
    expect(kot, contains('1 x $name'));
    expect(kot, contains('* $name'));
  });
}
