import 'package:bechakena/core/currency.dart';
import 'package:bechakena/core/format.dart';
import 'package:bechakena/core/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all supported currencies round trip both display languages exactly', () {
    for (final currency in ShopCurrency.values) {
      for (final locale in ['en', 'bn']) {
        for (final minor in [0, 1, -1, 125050, -123456789]) {
          final value = Money(minor);
          final text = formatTaka(value, currency: currency, locale: locale);
          expect(Money.parse(text, currency: currency), value,
              reason: '${currency.code}: $text');
        }
      }
    }
  });

  test('international grouping and Bangla digits are independent', () {
    expect(formatTaka(const Money(123456789), currency: ShopCurrency.usd),
        r'$1,234,567.89');
    expect(formatTaka(const Money(123456789), currency: ShopCurrency.inr,
        locale: 'bn'), '₹১২,৩৪,৫৬৭.৮৯');
    expect(formatAmount(const Money(-123456789), currency: ShopCurrency.eur),
        '-1,234,567.89');
  });

  test('unsupported exponents, foreign symbols and malformed grouping rejected', () {
    for (final code in ['JPY', 'KWD', 'XXX', '']) {
      expect(() => ShopCurrency.decode(code), throwsFormatException);
    }
    expect(ShopCurrency.decode(null), ShopCurrency.bdt);
    for (final text in ['1.234', '1,25', '1 2', '€12', '৳12', r'$1,23,456']) {
      expect(() => Money.parse(text, currency: ShopCurrency.usd),
          throwsFormatException, reason: text);
    }
    expect(Money.parse('USD ১২.৫০', currency: ShopCurrency.usd), const Money(1250));
    expect(Money.parse('AED 12.50', currency: ShopCurrency.aed), const Money(1250));
  });
}
