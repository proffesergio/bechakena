import 'package:bechakena/core/db/database.dart';
import 'package:bechakena/core/money.dart';
import 'package:bechakena/core/qty.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Future<Product> addProduct(String name, {int lowStockMilli = 5000}) =>
      db.productsDao.insertProduct(ProductsCompanion.insert(
        name: name,
        salePrice: const Money(1000),
        lowStockLevel: Value(Qty(lowStockMilli)),
      ));

  group('lowStockProducts', () {
    test('lists products at or below their low-stock level', () async {
      final rice = await addProduct('Rice', lowStockMilli: 5000);
      final oil = await addProduct('Oil', lowStockMilli: 5000);
      final salt = await addProduct('Salt', lowStockMilli: 5000);

      // Rice: 3 (below 5) → alert. Oil: 5 (== level) → alert. Salt: 20 → fine.
      await db.stockDao.addMovement(
          productId: rice.id, qtyDelta: const Qty(3000), type: MovementType.purchase);
      await db.stockDao.addMovement(
          productId: oil.id, qtyDelta: const Qty(5000), type: MovementType.purchase);
      await db.stockDao.addMovement(
          productId: salt.id, qtyDelta: const Qty(20000), type: MovementType.purchase);

      final low = await db.stockDao.lowStockProducts();
      final names = low.map((e) => e.product.name).toList();
      expect(names, containsAll(['Rice', 'Oil']));
      expect(names, isNot(contains('Salt')));
      // Carries the derived stock for display.
      final riceRow = low.firstWhere((e) => e.product.name == 'Rice');
      expect(riceRow.stock, const Qty(3000));
    });

    test('products with lowStockLevel 0 never alert', () async {
      final p = await addProduct('NoTrack', lowStockMilli: 0);
      // stock 0, level 0 → not an alert (0 <= 0 but level 0 means untracked)
      final low = await db.stockDao.lowStockProducts();
      expect(low.map((e) => e.product.id), isNot(contains(p.id)));
    });
  });

  group('expiringSoon', () {
    test('lists purchase batches expiring within the window', () async {
      final milk = await addProduct('Milk');
      final now = DateTime.utc(2025, 7, 9);
      // Expires in 5 days → within a 14-day window.
      await db.stockDao.addMovement(
          productId: milk.id,
          qtyDelta: const Qty(10000),
          type: MovementType.purchase,
          expiryDate: now.add(const Duration(days: 5)));
      // Expires in 60 days → outside the window.
      await db.stockDao.addMovement(
          productId: milk.id,
          qtyDelta: const Qty(10000),
          type: MovementType.purchase,
          expiryDate: now.add(const Duration(days: 60)));

      final soon =
          await db.stockDao.expiringSoon(within: const Duration(days: 14), now: now);
      expect(soon.length, 1);
      expect(soon.first.product.name, 'Milk');
      expect(soon.first.expiryDate, now.add(const Duration(days: 5)));
    });

    test('already-expired batches are included (window from now)', () async {
      final yogurt = await addProduct('Yogurt');
      final now = DateTime.utc(2025, 7, 9);
      await db.stockDao.addMovement(
          productId: yogurt.id,
          qtyDelta: const Qty(5000),
          type: MovementType.purchase,
          expiryDate: now.subtract(const Duration(days: 2)));
      final soon =
          await db.stockDao.expiringSoon(within: const Duration(days: 14), now: now);
      expect(soon.length, 1);
    });
  });
}
