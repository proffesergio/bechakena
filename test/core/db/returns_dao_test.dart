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

  Future<Product> addProduct({int price = 5000}) => db.productsDao
      .insertProduct(ProductsCompanion.insert(name: 'Rice', salePrice: Money(price)));

  Future<Sale> sell(Product p, {int qtyMilli = 3000}) => db.salesDao.finalizeSale(
        invoicePrefix: 'BK',
        items: [
          SaleDraftItem(
              productId: p.id,
              nameSnapshot: p.name,
              qty: Qty(qtyMilli),
              unitPrice: p.salePrice),
        ],
        tenders: [
          TenderDraft(
              method: PayMethod.cash,
              amount: p.salePrice.timesQty(Qty(qtyMilli)))
        ],
        now: DateTime.utc(2025, 7, 9),
      );

  group('createReturn', () {
    test('restocks returned qty and records the refund total', () async {
      final p = await addProduct(price: 5000);
      await db.stockDao.addMovement(
          productId: p.id, qtyDelta: const Qty(10000), type: MovementType.purchase);
      final sale = await sell(p, qtyMilli: 3000); // stock now 7 (10 - 3)
      expect(await db.stockDao.stockFor(p.id), const Qty(7000));

      final ret = await db.returnsDao.createReturn(
        originalSaleId: sale.id,
        items: [
          ReturnDraftItem(
              productId: p.id,
              nameSnapshot: p.name,
              qty: const Qty(2000),
              refundAmount: const Money(10000)),
        ],
        now: DateTime.utc(2025, 7, 9, 15),
      );

      expect(ret.refundTotal, const Money(10000));
      expect(ret.originalSaleId, sale.id);
      // 2 units restocked → stock back to 9.
      expect(await db.stockDao.stockFor(p.id), const Qty(9000));
      final items = await db.returnsDao.itemsOf(ret.id);
      expect(items.single.qty, const Qty(2000));
    });

    test('original sale stays immutable', () async {
      final p = await addProduct(price: 5000);
      final sale = await sell(p, qtyMilli: 3000);
      await db.returnsDao.createReturn(
        originalSaleId: sale.id,
        items: [
          ReturnDraftItem(
              productId: p.id,
              nameSnapshot: p.name,
              qty: const Qty(1000),
              refundAmount: const Money(5000)),
        ],
      );
      final reloaded = await (db.select(db.sales)
            ..where((s) => s.id.equals(sale.id)))
          .getSingle();
      expect(reloaded.total, const Money(15000));
      expect(reloaded.status, SaleStatus.finalized);
    });

    test('empty return is rejected', () {
      expect(() => db.returnsDao.createReturn(items: const []),
          throwsStateError);
    });

    test('manual (no product) return line refunds without a stock movement',
        () async {
      final ret = await db.returnsDao.createReturn(
        items: [
          ReturnDraftItem(
              nameSnapshot: 'Unlisted',
              qty: const Qty(1000),
              refundAmount: const Money(500)),
        ],
      );
      expect(ret.refundTotal, const Money(500));
      expect(await db.returnsDao.itemsOf(ret.id), hasLength(1));
    });
  });

  group('refundsInRange', () {
    test('sums refunds within the range', () async {
      final p = await addProduct();
      final sale = await sell(p);
      Future<void> refund(DateTime at, int amount) => db.returnsDao
          .createReturn(
            originalSaleId: sale.id,
            items: [
              ReturnDraftItem(
                  productId: p.id,
                  nameSnapshot: p.name,
                  qty: const Qty(1000),
                  refundAmount: Money(amount)),
            ],
            now: at,
          )
          .then((_) {});
      await refund(DateTime.utc(2025, 7, 8), 5000);
      await refund(DateTime.utc(2025, 7, 9), 5000);

      final total = await db.returnsDao.refundsInRange(
          start: DateTime.utc(2025, 7, 8), end: DateTime.utc(2025, 7, 10));
      expect(total, const Money(10000));
    });
  });
}
