import 'package:bechakena/core/money.dart';
import 'package:bechakena/core/pricing/pricing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bill discount reduces included tax consistently', () {
    expect(includedTax([const TaxableAmount(Money(11500), 1500)],
      billDiscount: const Money(1150)), const Money(1350));
  });
  test('mixed rate allocation preserves integer money', () {
    expect(includedTax([const TaxableAmount(Money(11500), 1500),
      const TaxableAmount(Money(10000), 0)], billDiscount: const Money(2150)), const Money(1350));
    expect(includedTax([const TaxableAmount(Money(11500), 1500)],
      billDiscount: const Money(11500)), Money.zero);
  });
}
