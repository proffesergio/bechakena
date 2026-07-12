import 'package:bechakena/core/money.dart';
import 'package:bechakena/core/qty.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Qty', () {
    test('fromCount: whole units in milli', () {
      expect(Qty.fromCount(3).milli, 3000);
    });

    test('parse decimals up to 3 places', () {
      expect(Qty.parse('1.5').milli, 1500);
      expect(Qty.parse('0.250').milli, 250);
      expect(Qty.parse('12').milli, 12000);
    });

    test('parse Bangla digits', () {
      expect(Qty.parse('১.৫').milli, 1500);
    });

    test('rejects garbage and >3 decimals', () {
      expect(() => Qty.parse('abc'), throwsFormatException);
      expect(() => Qty.parse('1.2345'), throwsFormatException);
    });

    test('display trims trailing zeros', () {
      expect(Qty.fromCount(3).display, '3');
      expect(const Qty(1500).display, '1.5');
      expect(const Qty(250).display, '0.25');
      expect(const Qty(1250).display, '1.25');
    });

    test('arithmetic', () {
      expect((const Qty(1500) + const Qty(500)).milli, 2000);
      expect((const Qty(1500) - const Qty(2000)).milli, -500);
      expect(const Qty(-500).isNegative, isTrue);
    });
  });

  group('Money × Qty', () {
    test('whole quantities', () {
      // 3 pcs @ ৳12.50
      expect(const Money(1250).timesQty(Qty.fromCount(3)).paisa, 3750);
    });

    test('fractional kg', () {
      // 1.5 kg @ ৳80.00/kg = ৳120.00
      expect(const Money(8000).timesQty(const Qty(1500)).paisa, 12000);
    });

    test('rounds half away from zero', () {
      // 0.333 kg @ ৳99.99 = 33.29667 → ৳33.30
      expect(const Money(9999).timesQty(const Qty(333)).paisa, 3330);
    });
  });
}
