import 'package:bechakena/core/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money construction', () {
    test('wraps integer paisa', () {
      expect(const Money(12550).paisa, 12550);
    });

    test('fromTaka multiplies by 100', () {
      expect(Money.fromTaka(125).paisa, 12500);
    });

    test('zero constant', () {
      expect(Money.zero.paisa, 0);
    });

    test('taka and paisaPart split', () {
      const m = Money(12550);
      expect(m.taka, 125);
      expect(m.paisaPart, 50);
    });
  });

  group('Money arithmetic', () {
    test('addition and subtraction', () {
      expect((const Money(1000) + const Money(250)).paisa, 1250);
      expect((const Money(1000) - const Money(250)).paisa, 750);
    });

    test('subtraction can go negative (due balances)', () {
      expect((const Money(100) - const Money(250)).paisa, -150);
      expect((const Money(100) - const Money(250)).isNegative, isTrue);
    });

    test('multiply by integer quantity', () {
      expect((const Money(1250) * 3).paisa, 3750);
    });

    test('comparisons', () {
      expect(const Money(100) < const Money(200), isTrue);
      expect(const Money(200) >= const Money(200), isTrue);
      expect(const Money(300) > const Money(200), isTrue);
    });
  });

  group('Money.percent (basis points)', () {
    test('exact percentage', () {
      // 5% of ৳99.00
      expect(const Money(9900).percent(500).paisa, 495);
    });

    test('rounds half away from zero', () {
      // 5% of 99 paisa = 4.95 → 5
      expect(const Money(99).percent(500).paisa, 5);
      // 1% of 50 paisa = 0.5 → 1
      expect(const Money(50).percent(100).paisa, 1);
    });

    test('rounds down below half', () {
      // 1% of 49 paisa = 0.49 → 0
      expect(const Money(49).percent(100).paisa, 0);
    });

    test('zero rate gives zero', () {
      expect(const Money(9900).percent(0).paisa, 0);
    });
  });

  group('VAT-inclusive extraction', () {
    test('extracts 15% VAT from gross', () {
      // Gross ৳115.00 at 15% → VAT ৳15.00, net ৳100.00
      const gross = Money(11500);
      expect(gross.vatPortionInclusive(1500).paisa, 1500);
      expect(gross.netOfVat(1500).paisa, 10000);
    });

    test('vat + net always equals gross (no lost paisa)', () {
      for (final grossPaisa in [1, 99, 100, 999, 12345, 99999]) {
        for (final bp in [500, 750, 1000, 1500]) {
          final gross = Money(grossPaisa);
          final vat = gross.vatPortionInclusive(bp);
          final net = gross.netOfVat(bp);
          expect((vat + net).paisa, grossPaisa,
              reason: 'gross=$grossPaisa bp=$bp');
        }
      }
    });

    test('rounding case: 100 paisa gross at 15%', () {
      // 100 * 1500 / 11500 = 13.04 → 13
      expect(const Money(100).vatPortionInclusive(1500).paisa, 13);
    });

    test('zero rate: no VAT', () {
      expect(const Money(11500).vatPortionInclusive(0).paisa, 0);
      expect(const Money(11500).netOfVat(0).paisa, 11500);
    });
  });

  group('Money.parse', () {
    test('plain taka', () {
      expect(Money.parse('125').paisa, 12500);
    });

    test('taka.paisa with two decimals', () {
      expect(Money.parse('125.50').paisa, 12550);
    });

    test('single decimal digit means tens of paisa', () {
      expect(Money.parse('125.5').paisa, 12550);
    });

    test('strips ৳ sign, commas and whitespace', () {
      expect(Money.parse('৳1,250.50').paisa, 125050);
      expect(Money.parse(' 1,250 ').paisa, 125000);
    });

    test('Bangla digits', () {
      expect(Money.parse('১২৫.৫০').paisa, 12550);
      expect(Money.parse('৳১,২৫০').paisa, 125000);
    });

    test('rejects garbage', () {
      expect(() => Money.parse('abc'), throwsFormatException);
      expect(() => Money.parse(''), throwsFormatException);
      expect(() => Money.parse('1.2.3'), throwsFormatException);
    });

    test('rejects more than two decimal places', () {
      expect(() => Money.parse('1.234'), throwsFormatException);
    });
  });

  group('Money canonical string', () {
    test('always two decimals, no symbol', () {
      expect(const Money(12550).asDecimalString, '125.50');
      expect(const Money(12500).asDecimalString, '125.00');
      expect(const Money(5).asDecimalString, '0.05');
    });

    test('negative amounts keep sign', () {
      expect(const Money(-12550).asDecimalString, '-125.50');
      expect(const Money(-5).asDecimalString, '-0.05');
    });
  });
}
