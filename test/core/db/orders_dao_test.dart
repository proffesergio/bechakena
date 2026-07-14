import 'package:bechakena/core/db/database.dart';
import 'package:bechakena/core/db/sale_draft.dart';
import 'package:bechakena/core/money.dart';
import 'package:bechakena/core/qty.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Future<Product> addProduct({int price = 5000, int stockMilli = 10000}) async {
    final p = await db.productsDao
        .insertProduct(ProductsCompanion.insert(name: 'Burger', salePrice: Money(price)));
    await db.stockDao.addMovement(
        productId: p.id, qtyDelta: Qty(stockMilli), type: MovementType.purchase);
    return p;
  }

  group('running order → settle', () {
    test('adding the same product twice merges into one unsent line', () async {
      final p = await addProduct();
      final order = await db.ordersDao
          .createOrder(orderType: OrderType.takeaway, customerName: 'Karim');
      await db.ordersDao.addProduct(order.id, p);
      await db.ordersDao.addProduct(order.id, p);

      final items = await db.ordersDao.itemsOf(order.id);
      expect(items, hasLength(1));
      expect(items.single.qty, const Qty(2000));
    });

    test('settling finalizes an immutable sale and decrements stock', () async {
      final p = await addProduct(price: 5000, stockMilli: 10000);
      final order =
          await db.ordersDao.createOrder(orderType: OrderType.takeaway);
      await db.ordersDao.addProduct(order.id, p);
      await db.ordersDao.addProduct(order.id, p); // qty 2 → total 100.00

      final sale = await db.ordersDao.settleOrder(
        orderId: order.id,
        tenders: [const TenderDraft(method: PayMethod.cash, amount: Money(10000))],
      );

      expect(sale.status, SaleStatus.finalized);
      expect(sale.total, const Money(10000));
      // Stock: 10 purchased − 2 sold = 8.
      expect(await db.stockDao.stockFor(p.id), const Qty(8000));

      final reloaded = await db.ordersDao.byId(order.id);
      expect(reloaded!.status, OrderStatus.settled);
      expect(reloaded.saleId, sale.id);
    });

    test('settling frees the table (no open order remains)', () async {
      final table = await db.into(db.diningTables).insertReturning(
          DiningTablesCompanion.insert(name: 'T1', seats: const Value(4)));
      final p = await addProduct();
      final order = await db.ordersDao
          .createOrder(tableId: table.id, orderType: OrderType.dineIn);
      await db.ordersDao.addProduct(order.id, p);

      expect(await db.ordersDao.openOrderForTable(table.id), isNotNull);
      await db.ordersDao.settleOrder(
        orderId: order.id,
        tenders: [const TenderDraft(method: PayMethod.cash, amount: Money(5000))],
      );
      expect(await db.ordersDao.openOrderForTable(table.id), isNull);
    });

    test('settling an order with no items is rejected', () async {
      final order =
          await db.ordersDao.createOrder(orderType: OrderType.takeaway);
      expect(
        () => db.ordersDao.settleOrder(orderId: order.id, tenders: const []),
        throwsStateError,
      );
    });
  });

  group('kitchen ticket (KOT)', () {
    test('unsent items are fired once, then a re-add starts a new line',
        () async {
      final p = await addProduct();
      final order =
          await db.ordersDao.createOrder(orderType: OrderType.takeaway);
      await db.ordersDao.addProduct(order.id, p);

      expect(await db.ordersDao.unsentItems(order.id), hasLength(1));
      await db.ordersDao.markKotSent(order.id);
      expect(await db.ordersDao.unsentItems(order.id), isEmpty);

      // A fired line is never mutated — a later addition is its own line.
      await db.ordersDao.addProduct(order.id, p);
      expect(await db.ordersDao.itemsOf(order.id), hasLength(2));
      expect(await db.ordersDao.unsentItems(order.id), hasLength(1));
    });
  });

  group('cancel', () {
    test('cancelled order is not open and has no sale side effects', () async {
      final p = await addProduct(stockMilli: 10000);
      final order =
          await db.ordersDao.createOrder(orderType: OrderType.takeaway);
      await db.ordersDao.addProduct(order.id, p);
      await db.ordersDao.cancelOrder(order.id);

      final open = await db.ordersDao.watchOpenOrders().first;
      expect(open, isEmpty);
      // Nothing sold: stock untouched.
      expect(await db.stockDao.stockFor(p.id), const Qty(10000));
    });
  });
}
