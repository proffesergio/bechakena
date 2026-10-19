import 'package:bechakena/core/db/database.dart';
import 'package:bechakena/core/db/sale_draft.dart';
import 'package:bechakena/core/money.dart';
import 'package:bechakena/core/qty.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression tests for read-path scoping: every read lookup must ignore
/// soft-deleted (`deletedAt != null`) rows, so deleted sales, baki payments,
/// purchases, movements, suppliers and SMS can never leak back into balances,
/// reports, derived stock or pickers (audit round 1: authz + dbrules).
void main() {
  late AppDatabase db;
  final now = DateTime.now().toUtc();

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Future<Sale> sell({String? customerId, Money paid = const Money(10000)}) async {
    final product = await db.productsDao.insertProduct(
        ProductsCompanion.insert(name: 'Rice', salePrice: const Money(10000)));
    return db.salesDao.finalizeSale(
      invoicePrefix: 'BK',
      customerId: customerId,
      items: [
        SaleDraftItem(
            productId: product.id,
            nameSnapshot: 'Rice',
            qty: const Qty(1000),
            unitPrice: const Money(10000)),
      ],
      tenders: [TenderDraft(method: PayMethod.cash, amount: paid)],
      now: now,
    );
  }

  group('customer balances (baki khata)', () {
    test('dueFor ignores soft-deleted sales', () async {
      final customer = await db.customersDao
          .insertCustomer(CustomersCompanion.insert(name: 'Karim'));
      final sale = await sell(customerId: customer.id, paid: const Money(0));
      expect(await db.customersDao.dueFor(customer.id), const Money(10000));

      await (db.update(db.sales)..where((s) => s.id.equals(sale.id)))
          .write(SalesCompanion(deletedAt: Value(now)));
      expect(await db.customersDao.dueFor(customer.id), const Money(0));
    });

    test('dueFor ignores soft-deleted due payments', () async {
      final customer = await db.customersDao
          .insertCustomer(CustomersCompanion.insert(name: 'Karim'));
      await sell(customerId: customer.id, paid: const Money(0));
      final payment = await db.customersDao.addDuePayment(
          customerId: customer.id,
          amount: const Money(4000),
          method: PayMethod.cash);
      expect(await db.customersDao.dueFor(customer.id), const Money(6000));

      await (db.update(db.duePayments)..where((p) => p.id.equals(payment.id)))
          .write(DuePaymentsCompanion(deletedAt: Value(now)));
      expect(await db.customersDao.dueFor(customer.id), const Money(10000));
    });

    test('watchAll hides soft-deleted customers', () async {
      final customer = await db.customersDao
          .insertCustomer(CustomersCompanion.insert(name: 'Karim'));
      expect((await db.customersDao.watchAll().first).single.id, customer.id);

      await (db.update(db.customers)..where((c) => c.id.equals(customer.id)))
          .write(CustomersCompanion(deletedAt: Value(now)));
      expect(await db.customersDao.watchAll().first, isEmpty);
    });
  });

  group('sales reads', () {
    test('watchRecent / byId / aggregates hide soft-deleted sales', () async {
      final sale = await sell();
      expect((await db.salesDao.watchRecent().first).single.id, sale.id);
      final totals = await db.salesDao.dailyTotals(
          start: now.subtract(const Duration(days: 1)),
          end: now.add(const Duration(days: 1)));
      expect(totals.single.total, const Money(10000));

      await (db.update(db.sales)..where((s) => s.id.equals(sale.id)))
          .write(SalesCompanion(deletedAt: Value(now)));
      expect(await db.salesDao.watchRecent().first, isEmpty);
      expect(await db.salesDao.byId(sale.id), isNull);
      final after = await db.salesDao.dailyTotals(
          start: now.subtract(const Duration(days: 1)),
          end: now.add(const Duration(days: 1)));
      expect(after, isEmpty);
    });

    test('itemsOf / paymentsOf hide soft-deleted child rows', () async {
      final sale = await sell(paid: const Money(10000));
      final item = (await db.salesDao.itemsOf(sale.id)).single;
      final tender = (await db.salesDao.paymentsOf(sale.id)).single;

      await (db.update(db.saleItems)..where((i) => i.id.equals(item.id)))
          .write(SaleItemsCompanion(deletedAt: Value(now)));
      await (db.update(db.salePayments)..where((p) => p.id.equals(tender.id)))
          .write(SalePaymentsCompanion(deletedAt: Value(now)));
      expect(await db.salesDao.itemsOf(sale.id), isEmpty);
      expect(await db.salesDao.paymentsOf(sale.id), isEmpty);
    });
  });

  group('purchase reads', () {
    test('watchRecent / itemsOf hide soft-deleted rows', () async {
      final product = await db.productsDao.insertProduct(
          ProductsCompanion.insert(name: 'Rice', salePrice: const Money(5000)));
      final purchase = await db.purchasesDao.createPurchase(items: [
        PurchaseDraftItem(
            productId: product.id, qty: const Qty(5000), unitCost: const Money(4000)),
      ]);
      expect(
          (await db.purchasesDao.watchRecent().first).single.id, purchase.id);
      final item = (await db.purchasesDao.itemsOf(purchase.id)).single;

      await (db.update(db.purchaseItems)..where((i) => i.id.equals(item.id)))
          .write(PurchaseItemsCompanion(deletedAt: Value(now)));
      expect(await db.purchasesDao.itemsOf(purchase.id), isEmpty);

      await (db.update(db.purchases)..where((p) => p.id.equals(purchase.id)))
          .write(PurchasesCompanion(deletedAt: Value(now)));
      expect(await db.purchasesDao.watchRecent().first, isEmpty);
    });

    test('watchSuppliers hides soft-deleted suppliers', () async {
      final supplier = await db.purchasesDao
          .insertSupplier(SuppliersCompanion.insert(name: 'Amber Traders'));
      expect((await db.purchasesDao.watchSuppliers().first).single.id,
          supplier.id);

      await (db.update(db.suppliers)..where((s) => s.id.equals(supplier.id)))
          .write(SuppliersCompanion(deletedAt: Value(now)));
      expect(await db.purchasesDao.watchSuppliers().first, isEmpty);
    });
  });

  group('derived stock', () {
    test('stockFor ignores soft-deleted movements (never stored)', () async {
      final product = await db.productsDao.insertProduct(
          ProductsCompanion.insert(name: 'Rice', salePrice: const Money(5000)));
      await db.purchasesDao.createPurchase(items: [
        PurchaseDraftItem(
            productId: product.id, qty: const Qty(5000), unitCost: const Money(4000)),
      ]);
      expect(await db.stockDao.stockFor(product.id), const Qty(5000));

      await (db.update(db.stockMovements)
            ..where((m) => m.productId.equals(product.id)))
          .write(StockMovementsCompanion(deletedAt: Value(now)));
      expect(await db.stockDao.stockFor(product.id), Qty.zero);
    });
  });

  group('catalog, orders, returns, sms', () {
    test('products.byId hides soft-deleted products', () async {
      final product = await db.productsDao.insertProduct(
          ProductsCompanion.insert(name: 'Rice', salePrice: const Money(5000)));
      await db.productsDao.softDelete(product.id);
      expect(await db.productsDao.byId(product.id), isNull);
    });

    test('orders.byId hides cancelled (soft-deleted) orders', () async {
      final order = await db.ordersDao.createOrder(
          orderType: OrderType.takeaway, customerName: 'Guest');
      await db.ordersDao
          .addManual(order.id, name: 'Tea', price: const Money(2000));
      expect((await db.ordersDao.byId(order.id))!.id, order.id);

      await db.ordersDao.cancelOrder(order.id);
      expect(await db.ordersDao.byId(order.id), isNull);
    });

    test('returns reads hide soft-deleted rows', () async {
      final ret = await db.returnsDao.createReturn(
        now: now,
        items: const [
          ReturnDraftItem(
              nameSnapshot: 'Tea', qty: Qty(1000), refundAmount: Money(2000)),
        ],
      );
      expect((await db.returnsDao.watchRecent().first).single.id, ret.id);
      const oneSecond = Duration(seconds: 1);
      expect(
          await db.returnsDao.refundsInRange(
              start: now.subtract(oneSecond), end: now.add(oneSecond)),
          const Money(2000));

      await (db.update(db.returns)..where((r) => r.id.equals(ret.id)))
          .write(ReturnsCompanion(deletedAt: Value(now)));
      expect(await db.returnsDao.watchRecent().first, isEmpty);
      expect(
          await db.returnsDao.refundsInRange(
              start: now.subtract(oneSecond), end: now.add(oneSecond)),
          const Money(0));
    });

    test('sms log hides soft-deleted entries', () async {
      final sms = await db.smsDao.enqueue(
          phone: '01700000000',
          kind: SmsKind.receipt,
          body: 'Thanks',
          at: now);
      expect((await db.smsDao.watchLog().first).single.id, sms.id);

      await (db.update(db.smsLog)..where((s) => s.id.equals(sms.id)))
          .write(SmsLogCompanion(deletedAt: Value(now)));
      expect(await db.smsDao.watchLog().first, isEmpty);
      expect(await db.smsDao.watchQueued().first, isEmpty);
    });
  });
}
