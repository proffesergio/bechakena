import 'package:bechakena/core/money.dart';
import 'package:bechakena/core/printing/escpos.dart';
import 'package:bechakena/core/printing/receipt.dart';
import 'package:bechakena/core/qty.dart';
import 'package:flutter_test/flutter_test.dart';

ReceiptData sampleReceipt() => ReceiptData(
      shopName: 'Karim Store',
      address: 'Mirpur 10, Dhaka',
      phone: '01711-000000',
      invoiceNo: 'BK-250709-0042',
      dateTime: DateTime.utc(2025, 7, 9, 14, 30),
      items: const [
        ReceiptItem(
            name: 'Miniket Rice 5kg',
            qty: Qty(2000),
            unitPrice: Money(45000),
            lineTotal: Money(90000)),
        ReceiptItem(
            name: 'Soybean Oil 1L with a very long name',
            qty: Qty(1000),
            unitPrice: Money(18500),
            lineTotal: Money(18500)),
      ],
      subtotal: const Money(108500),
      discount: const Money(500),
      vat: Money.zero,
      total: const Money(108000),
      paid: const Money(108000),
      due: Money.zero,
      change: const Money(2000),
      footer: 'Thank you! Powered by BechaKena',
    );

void main() {
  group('renderReceiptText', () {
    test('no line exceeds the paper width', () {
      for (final width in [32, 48]) {
        final lines = renderReceiptText(sampleReceipt(), width: width).split('\n');
        for (final line in lines) {
          expect(line.length, lessThanOrEqualTo(width),
              reason: 'width=$width line="$line"');
        }
      }
    });

    test('includes header, invoice and items', () {
      final text = renderReceiptText(sampleReceipt(), width: 32);
      expect(text, contains('Karim Store'));
      expect(text, contains('BK-250709-0042'));
      expect(text, contains('Miniket Rice 5kg'));
      // qty x unit price detail line
      expect(text, contains('2 x 450.00'));
    });

    test('amounts use Tk (thermal printers have no Taka glyph)', () {
      final text = renderReceiptText(sampleReceipt(), width: 32);
      expect(text, contains('Tk'));
      expect(text, isNot(contains('৳')));
    });

    test('total row is right-aligned to the paper edge', () {
      final lines = renderReceiptText(sampleReceipt(), width: 32).split('\n');
      final totalLine = lines.firstWhere((l) => l.startsWith('TOTAL'));
      expect(totalLine.length, 32);
      expect(totalLine.endsWith('1,080.00'), isTrue);
    });

    test('due line appears only when there is due', () {
      expect(renderReceiptText(sampleReceipt(), width: 32),
          isNot(contains('DUE')));
      final withDue = sampleReceipt().copyWith(
          due: const Money(5000), paid: const Money(103000), change: Money.zero);
      expect(renderReceiptText(withDue, width: 32), contains('DUE'));
    });
  });

  group('escPosBytes', () {
    test('starts with printer init and ends with paper cut', () {
      final bytes = escPosBytes('hello');
      expect(bytes.sublist(0, 2), [0x1B, 0x40]); // ESC @
      final tail = bytes.sublist(bytes.length - 4);
      expect(tail, [0x1D, 0x56, 0x42, 0x00]); // GS V 66 0 partial cut
    });

    test('drawer kick pulse included when requested', () {
      final bytes = escPosBytes('x', kickDrawer: true);
      expect(_containsSeq(bytes, [0x1B, 0x70, 0x00, 0x19, 0xFA]), isTrue);
      final without = escPosBytes('x');
      expect(_containsSeq(without, [0x1B, 0x70, 0x00, 0x19, 0xFA]), isFalse);
    });

    test('non-ASCII characters are replaced, never crash the printer', () {
      final bytes = escPosBytes('চাল ৳50');
      expect(bytes.every((b) => b <= 0xFF), isTrue);
    });
  });
}

bool _containsSeq(List<int> haystack, List<int> needle) {
  for (var i = 0; i + needle.length <= haystack.length; i++) {
    var match = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        match = false;
        break;
      }
    }
    if (match) return true;
  }
  return false;
}
