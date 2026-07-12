import 'package:bechakena/core/csv/product_csv.dart';
import 'package:bechakena/core/money.dart';
import 'package:bechakena/core/qty.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseCsv', () {
    test('splits simple rows and columns', () {
      final rows = parseCsv('a,b,c\n1,2,3');
      expect(rows, [
        ['a', 'b', 'c'],
        ['1', '2', '3'],
      ]);
    });

    test('handles quoted fields with commas and quotes', () {
      final rows = parseCsv('name,note\n"Rice, 5kg","he said ""hi"""');
      expect(rows[1], ['Rice, 5kg', 'he said "hi"']);
    });

    test('handles quoted newlines', () {
      final rows = parseCsv('a\n"line1\nline2"');
      expect(rows[1], ['line1\nline2']);
    });

    test('ignores a trailing blank line', () {
      expect(parseCsv('a,b\n1,2\n').length, 2);
    });

    test('handles CRLF line endings', () {
      expect(parseCsv('a,b\r\n1,2'), [
        ['a', 'b'],
        ['1', '2'],
      ]);
    });
  });

  group('encodeCsv', () {
    test('quotes fields that need it, escapes quotes', () {
      final out = encodeCsv([
        ['name', 'note'],
        ['Rice, 5kg', 'he said "hi"'],
      ]);
      expect(out, 'name,note\r\n"Rice, 5kg","he said ""hi"""');
    });

    test('round-trips through parseCsv', () {
      final data = [
        ['a', 'b,c', 'd"e'],
        ['1', 'x\ny', '3'],
      ];
      expect(parseCsv(encodeCsv(data)), data);
    });
  });

  group('parseProductRows', () {
    final header =
        'name,nameBn,barcode,unit,price,vatBp,openingStock';

    test('parses a valid product row', () {
      final result = parseProductRows(
          '$header\nRice,চাল,12345,kg,50.00,0,100');
      expect(result.errors, isEmpty);
      final p = result.products.single;
      expect(p.name, 'Rice');
      expect(p.nameBn, 'চাল');
      expect(p.barcode, '12345');
      expect(p.unit, 'kg');
      expect(p.salePrice, const Money(5000));
      expect(p.vatRateBp, 0);
      expect(p.openingStock, const Qty(100000));
    });

    test('optional columns can be blank', () {
      final result = parseProductRows('$header\nSalt,,,,20,,');
      expect(result.errors, isEmpty);
      final p = result.products.single;
      expect(p.nameBn, isNull);
      expect(p.barcode, isNull);
      expect(p.unit, 'pcs');
      expect(p.salePrice, const Money(2000));
      expect(p.openingStock, Qty.zero);
    });

    test('reports row-level errors without aborting the whole import', () {
      final result = parseProductRows(
          '$header\nGood,,,,50,,\n,,,,10,,\nBadPrice,,,,abc,,');
      expect(result.products, hasLength(1)); // only "Good"
      expect(result.errors, hasLength(2)); // missing name, bad price
      expect(result.errors.first, contains('3')); // row number (1-based)
    });

    test('rejects a missing required header', () {
      final result = parseProductRows('name,price\nRice');
      expect(result.errors, isNotEmpty);
      expect(result.products, isEmpty);
    });

    test('is tolerant of header column order', () {
      final result =
          parseProductRows('price,name\n50,Rice');
      expect(result.errors, isEmpty);
      expect(result.products.single.name, 'Rice');
      expect(result.products.single.salePrice, const Money(5000));
    });
  });

  group('productsToCsv', () {
    test('emits a header and one row per product', () {
      final csv = productsToCsv([
        const ProductCsvRow(
            name: 'Rice',
            nameBn: 'চাল',
            barcode: '12345',
            unit: 'kg',
            salePrice: Money(5000),
            vatRateBp: 0,
            openingStock: Qty(100000)),
      ]);
      final rows = parseCsv(csv);
      expect(rows.first, contains('name'));
      expect(rows[1], contains('Rice'));
      expect(rows[1], contains('50.00'));
    });
  });
}
