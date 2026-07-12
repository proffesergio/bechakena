import 'package:bechakena/core/db/database.dart';
import 'package:bechakena/core/db/sale_draft.dart';
import 'package:bechakena/core/money.dart';
import 'package:bechakena/core/qty.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<Product> addProduct({
    String name = 'Rice 1kg',
    int pricePaisa = 5000,
    int vatRateBp = 0,
    String unit = 'pcs',
  }) {
    return db.productsDao.insertProduct(ProductsCompanion.insert(
      name: name,
      unit: Value(unit),
      salePrice: Money(pricePaisa),
      vatRateBp: Value(vatRateBp),
    ));
  }

  group('stock derivation', () {
    test('stock is SUM of movement deltas', () async {
      final p = await addProduct();
      await db.stockDao.addMovement(
          productId: p.id, qtyDelta: const Qty(10000), type: MovementType.purchase);
      await db.stockDao.addMovement(
          productId: p.id, qtyDelta: const Qty(-3000), type: MovementType.sale);
      await db.stockDao.addMovement(
          productId: p.id, qtyDelta: const Qty(-1000), type: MovementType.adjustment);

      expect(await db.stockDao.stockFor(p.id), const Qty(6000));
    });

    test('product with no movements has zero stock', () async {
      final p = await addProduct();
      expect(await db.stockDao.stockFor(p.id), Qty.zero);
    });

    test('watchStock reflects new movements', () async {
      final p = await addProduct();
      expect(await db.stockDao.watchStockFor(p.id).first, Qty.zero);
      await db.stockDao.addMovement(
          productId: p.id, qtyDelta: const Qty(5000), type: MovementType.purchase);
      expect(await db.stockDao.watchStockFor(p.id).first, const Qty(5000));
    });
  });

  group('finalizeSale', () {
    final at = DateTime.utc(2025, 7, 9, 14, 30);

    SaleDraftItem itemFor(Product p, {int qtyMilli = 1000, Money? lineDiscount}) {
      return SaleDraftItem(
        productId: p.id,
        nameSnapshot: p.name,
        qty: Qty(qtyMilli),
        unitPrice: p.salePrice,
        vatRateBp: p.vatRateBp,
        lineDiscount: lineDiscount ?? Money.zero,
      );
    }

    test('cash sale: totals, invoice number, stock decrement', () async {
      final p = await addProduct(pricePaisa: 5000);
      await db.stockDao.addMovement(
          productId: p.id, qtyDelta: const Qty(10000), type: MovementType.purchase);

      final sale = await db.salesDao.finalizeSale(
        invoicePrefix: 'BK',
        items: [itemFor(p, qtyMilli: 2000)],
        tenders: [const TenderDraft(method: PayMethod.cash, amount: Money(20000))],
        now: at,
      );

      expect(sale.invoiceNo, 'BK-250709-0001');
      expect(sale.subtotal, const Money(10000));
      expect(sale.total, const Money(10000));
      expect(sale.paid, const Money(10000));
      expect(sale.due, Money.zero);
      expect(sale.status, SaleStatus.finalized);
      // Stock derived down to 8.
      expect(await db.stockDao.stockFor(p.id), const Qty(8000));
      // Items + payments persisted.
      expect((await db.salesDao.itemsOf(sale.id)).length, 1);
      final payments = await db.salesDao.paymentsOf(sale.id);
      expect(payments.single.amount, const Money(20000));
    });

    test('daily sequence increments and resets next day', () async {
      final p = await addProduct();
      Future<Sale> sell(DateTime when) => db.salesDao.finalizeSale(
            invoicePrefix: 'BK',
            items: [itemFor(p)],
            tenders: [const TenderDraft(method: PayMethod.cash, amount: Money(5000))],
            now: when,
          );

      expect((await sell(at)).invoiceNo, 'BK-250709-0001');
      expect((await sell(at)).invoiceNo, 'BK-250709-0002');
      expect((await sell(at.add(const Duration(days: 1)))).invoiceNo,
          'BK-250710-0001');
    });

    test('VAT-inclusive extraction per line', () async {
      // ৳115.00 shelf price at 15% VAT → net 100.00 + VAT 15.00
      final p = await addProduct(pricePaisa: 11500, vatRateBp: 1500);
      final sale = await db.salesDao.finalizeSale(
        invoicePrefix: 'BK',
        items: [itemFor(p)],
        tenders: [const TenderDraft(method: PayMethod.cash, amount: Money(11500))],
        now: at,
      );
      expect(sale.vat, const Money(1500));
      expect(sale.total, const Money(11500));
    });

    test('line discount and bill discount both reduce total', () async {
      // 1.5 kg @ ৳80.00 = 120.00, line discount 5.00 → 115.00
      final p = await addProduct(pricePaisa: 8000, unit: 'kg');
      final sale = await db.salesDao.finalizeSale(
        invoicePrefix: 'BK',
        items: [
          itemFor(p, qtyMilli: 1500, lineDiscount: const Money(500)),
        ],
        billDiscount: const Money(1000),
        tenders: [const TenderDraft(method: PayMethod.cash, amount: Money(10500))],
        now: at,
      );
      expect(sale.subtotal, const Money(11500));
      expect(sale.discount, const Money(1000));
      expect(sale.total, const Money(10500));
      final items = await db.salesDao.itemsOf(sale.id);
      expect(items.single.lineTotal, const Money(11500));
    });

    test('under-tendered sale requires a customer (baki)', () async {
      final p = await addProduct(pricePaisa: 10000);
      expect(
        () => db.salesDao.finalizeSale(
          invoicePrefix: 'BK',
          items: [itemFor(p)],
          tenders: [const TenderDraft(method: PayMethod.cash, amount: Money(4000))],
          now: at,
        ),
        throwsArgumentError,
      );
    });

    test('empty sale is rejected', () async {
      expect(
        () => db.salesDao.finalizeSale(
          invoicePrefix: 'BK',
          items: const [],
          tenders: const [],
          now: at,
        ),
        throwsStateError,
      );
    });

    test('due sale books the remainder against the customer', () async {
      final p = await addProduct(pricePaisa: 10000);
      final customer = await db.customersDao
          .insertCustomer(CustomersCompanion.insert(name: 'Karim'));

      final sale = await db.salesDao.finalizeSale(
        invoicePrefix: 'BK',
        customerId: customer.id,
        items: [itemFor(p)],
        tenders: [const TenderDraft(method: PayMethod.cash, amount: Money(4000))],
        now: at,
      );

      expect(sale.paid, const Money(4000));
      expect(sale.due, const Money(6000));
      expect(await db.customersDao.dueFor(customer.id), const Money(6000));
    });
  });

  group('customer due (baki khata)', () {
    test('due payments pay down the balance', () async {
      final p = await addProduct(pricePaisa: 10000);
      final customer = await db.customersDao
          .insertCustomer(CustomersCompanion.insert(name: 'Rahima'));

      await db.salesDao.finalizeSale(
        invoicePrefix: 'BK',
        customerId: customer.id,
        items: [
          SaleDraftItem(
            productId: p.id,
            nameSnapshot: p.name,
            qty: Qty.fromCount(1),
            unitPrice: p.salePrice,
            vatRateBp: 0,
          ),
        ],
        tenders: const [],
        now: DateTime.utc(2025, 7, 9),
      );
      expect(await db.customersDao.dueFor(customer.id), const Money(10000));

      await db.customersDao.addDuePayment(
        customerId: customer.id,
        amount: const Money(6000),
        method: PayMethod.cash,
      );
      expect(await db.customersDao.dueFor(customer.id), const Money(4000));
    });

    test('customer with no history owes nothing', () async {
      final customer = await db.customersDao
          .insertCustomer(CustomersCompanion.insert(name: 'New'));
      expect(await db.customersDao.dueFor(customer.id), Money.zero);
    });
  });

  group('sync contract', () {
    test('every inserted row carries id, updatedAt and deviceId', () async {
      final p = await addProduct();
      expect(p.id, isNotEmpty);
      expect(p.deviceId, isNotEmpty);
      expect(p.deletedAt, null);
      // UUIDv7: version nibble is 7.
      expect(p.id[14], '7');
    });
  });
}
