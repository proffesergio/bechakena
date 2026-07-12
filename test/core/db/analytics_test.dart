import 'package:bechakena/core/db/database.dart';
import 'package:bechakena/core/db/sale_draft.dart';
import 'package:bechakena/core/money.dart';
import 'package:bechakena/core/qty.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Future<Product> product(String name, int price) =>
      db.productsDao.insertProduct(
          ProductsCompanion.insert(name: name, salePrice: Money(price)));

  Future<Sale> sell(Product p, DateTime at,
      {int qtyMilli = 1000, PayMethod method = PayMethod.cash}) {
    final total = p.salePrice.timesQty(Qty(qtyMilli));
    return db.salesDao.finalizeSale(
      invoicePrefix: 'BK',
      items: [
        SaleDraftItem(
            productId: p.id,
            nameSnapshot: p.name,
            qty: Qty(qtyMilli),
            unitPrice: p.salePrice),
      ],
      tenders: [TenderDraft(method: method, amount: total)],
      now: at,
    );
  }

  final day1 = DateTime.utc(2025, 7, 7, 10);
  final day2 = DateTime.utc(2025, 7, 8, 11);
  final day3 = DateTime.utc(2025, 7, 9, 12);
  final start = DateTime.utc(2025, 7, 7);
  final end = DateTime.utc(2025, 7, 10);

  group('dailyTotals', () {
    test('groups sales by day with totals and counts', () async {
      final rice = await product('Rice', 5000);
      await sell(rice, day1);
      await sell(rice, day1, qtyMilli: 2000);
      await sell(rice, day3);

      final days = await db.salesDao.dailyTotals(start: start, end: end);
      expect(days.length, 2);
      expect(days.first.day, '2025-07-07');
      expect(days.first.total, const Money(15000)); // 50 + 100
      expect(days.first.count, 2);
      expect(days.last.day, '2025-07-09');
      expect(days.last.total, const Money(5000));
    });

    test('empty range returns empty list', () async {
      expect(await db.salesDao.dailyTotals(start: start, end: end), isEmpty);
    });
  });

  group('topProducts', () {
    test('ranks by revenue within range', () async {
      final rice = await product('Rice', 5000);
      final oil = await product('Oil', 18000);
      await sell(rice, day1, qtyMilli: 3000); // 150.00
      await sell(oil, day2); // 180.00
      await sell(rice, day2); // 50.00 → rice 200.00 total

      final top = await db.salesDao.topProducts(start: start, end: end);
      expect(top.length, 2);
      expect(top.first.name, 'Rice');
      expect(top.first.revenue, const Money(20000));
      expect(top.first.qty, const Qty(4000));
      expect(top.last.name, 'Oil');
    });

    test('sales outside the range are excluded', () async {
      final rice = await product('Rice', 5000);
      await sell(rice, DateTime.utc(2025, 6, 1));
      expect(await db.salesDao.topProducts(start: start, end: end), isEmpty);
    });
  });

  group('paymentTotals', () {
    test('sums tender amounts per method', () async {
      final rice = await product('Rice', 5000);
      await sell(rice, day1); // cash 50
      await sell(rice, day2, method: PayMethod.bkash); // bkash 50
      await sell(rice, day3, method: PayMethod.bkash); // bkash 50

      final totals = await db.salesDao.paymentTotals(start: start, end: end);
      expect(totals[PayMethod.cash], const Money(5000));
      expect(totals[PayMethod.bkash], const Money(10000));
      expect(totals.containsKey(PayMethod.card), isFalse);
    });
  });
}
