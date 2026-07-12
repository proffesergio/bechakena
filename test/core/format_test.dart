import 'package:bechakena/core/format.dart';
import 'package:bechakena/core/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatTaka (en locale)', () {
    test('small amount', () {
      expect(formatTaka(const Money(12550)), '৳125.50');
    });

    test('thousand uses lakh-style grouping', () {
      expect(formatTaka(Money.fromTaka(1000)), '৳1,000.00');
    });

    test('lakh grouping: last 3 digits then groups of 2', () {
      expect(formatTaka(Money.fromTaka(100000)), '৳1,00,000.00');
      expect(formatTaka(const Money(12345678)), '৳1,23,456.78');
      expect(formatTaka(Money.fromTaka(12345678)), '৳1,23,45,678.00');
    });

    test('zero', () {
      expect(formatTaka(Money.zero), '৳0.00');
    });

    test('negative amount', () {
      expect(formatTaka(const Money(-12550)), '-৳125.50');
    });
  });

  group('formatTaka (bn locale)', () {
    test('uses Bangla digits', () {
      expect(formatTaka(const Money(12550), locale: 'bn'), '৳১২৫.৫০');
    });

    test('lakh grouping with Bangla digits', () {
      expect(
        formatTaka(const Money(12345678), locale: 'bn'),
        '৳১,২৩,৪৫৬.৭৮',
      );
    });
  });

  group('toBanglaDigits', () {
    test('converts every ASCII digit', () {
      expect(toBanglaDigits('0123456789'), '০১২৩৪৫৬৭৮৯');
    });

    test('leaves non-digits untouched', () {
      expect(toBanglaDigits('INV-042 (৳)'), 'INV-০৪২ (৳)');
    });
  });
}
