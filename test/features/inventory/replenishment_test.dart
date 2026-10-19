import 'package:bechakena/core/qty.dart';
import 'package:bechakena/features/inventory/logic/replenishment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('demand covers lead time and target horizon', () {
    final p = planReplenishment(
      stock: const Qty(10000),
      sold: const Qty(56000),
      minimum: Qty.zero,
    );
    expect(p.suggested.milli, 32000);
    expect(p.daysRemaining, 5);
  });
  test('no history uses minimum and does not invent days cover', () {
    final p = planReplenishment(
      stock: const Qty(-1000),
      sold: Qty.zero,
      minimum: const Qty(5000),
    );
    expect(p.suggested.milli, 6000);
    expect(p.daysRemaining, isNull);
  });
  test('whole pieces round up; weighted goods preserve milli-units', () {
    final weighted = planReplenishment(
      stock: Qty.zero,
      sold: const Qty(1000),
      minimum: Qty.zero,
    );
    final pieces = planReplenishment(
      stock: Qty.zero,
      sold: const Qty(1000),
      minimum: Qty.zero,
      wholeUnits: true,
    );
    expect(weighted.suggested.milli, 750);
    expect(pieces.suggested.milli, 1000);
  });
  test('sufficient stock never suggests a negative order', () {
    expect(
      planReplenishment(
        stock: const Qty(100000),
        sold: const Qty(1000),
        minimum: Qty.zero,
      ).suggested.milli,
      0,
    );
  });
  test('invalid planning windows are rejected', () {
    expect(
      () => planReplenishment(
        stock: Qty.zero,
        sold: Qty.zero,
        minimum: Qty.zero,
        historyDays: 0,
      ),
      throwsArgumentError,
    );
  });
}
