import 'package:bechakena/core/db/database.dart';
import 'package:bechakena/core/money.dart';
import 'package:bechakena/core/qty.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  group('SettingsDao', () {
    test('missing key returns null', () async {
      expect(await db.settingsDao.getValue('printer.host'), null);
    });

    test('set then get round-trips', () async {
      await db.settingsDao.setValue('printer.host', '192.168.0.50');
      expect(await db.settingsDao.getValue('printer.host'), '192.168.0.50');
    });

    test('set overwrites existing value (upsert)', () async {
      await db.settingsDao.setValue('locale', 'bn');
      await db.settingsDao.setValue('locale', 'en');
      expect(await db.settingsDao.getValue('locale'), 'en');
    });
  });

  group('PurchasesDao', () {
    test('createPurchase restocks and totals cost atomically', () async {
      final p = await db.productsDao.insertProduct(ProductsCompanion.insert(
          name: 'Rice', salePrice: const Money(5000)));
      final expiry = DateTime.utc(2026, 1, 1);

      final purchase = await db.purchasesDao.createPurchase(
        invoiceRef: 'SUP-778',
        items: [
          PurchaseDraftItem(
              productId: p.id, qty: const Qty(10000), unitCost: const Money(4200)),
          PurchaseDraftItem(
              productId: p.id,
              qty: const Qty(5000),
              unitCost: const Money(4100),
              expiryDate: expiry),
        ],
      );

      // 10 * 42.00 + 5 * 41.00 = 420 + 205 = 625.00
      expect(purchase.totalCost, const Money(62500));
      expect(await db.stockDao.stockFor(p.id), const Qty(15000));

      final items = await db.purchasesDao.itemsOf(purchase.id);
      expect(items.length, 2);
      expect(items.where((i) => i.expiryDate != null).length, 1);
    });

    test('empty purchase is rejected', () {
      expect(() => db.purchasesDao.createPurchase(items: const []),
          throwsStateError);
    });

    test('suppliers can be created and listed', () async {
      await db.purchasesDao.insertSupplier(
          SuppliersCompanion.insert(name: 'Dhaka Traders'));
      final all = await db.purchasesDao.watchSuppliers().first;
      expect(all.single.name, 'Dhaka Traders');
    });
  });
}
