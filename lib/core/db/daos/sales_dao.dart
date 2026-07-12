import 'package:drift/drift.dart';

import '../../invoice_number.dart';
import '../../money.dart';
import '../../qty.dart';
import '../database.dart';
import '../sale_draft.dart';

part 'sales_dao.g.dart';

/// One day's aggregated sales (dashboard trend).
class DailyTotal {
  const DailyTotal({required this.day, required this.total, required this.count});

  /// ISO date, e.g. "2025-07-09".
  final String day;
  final Money total;
  final int count;
}

/// One product's aggregated sales within a range (dashboard ranking).
class TopProduct {
  const TopProduct({required this.name, required this.qty, required this.revenue});

  final String name;
  final Qty qty;
  final Money revenue;
}

@DriftAccessor(tables: [Sales, SaleItems, SalePayments, StockMovements])
class SalesDao extends DatabaseAccessor<AppDatabase> with _$SalesDaoMixin {
  SalesDao(super.db);

  /// Finalizes a sale atomically: sale row + items + payments + stock
  /// movements in one transaction. The resulting sale is immutable.
  ///
  /// Tender short of the total becomes due and requires [customerId].
  /// Over-tender (change given back) never records paid > total.
  Future<Sale> finalizeSale({
    required String invoicePrefix,
    int deviceNo = 0,
    String? staffId,
    String? customerId,
    required List<SaleDraftItem> items,
    required List<TenderDraft> tenders,
    Money billDiscount = Money.zero,
    DateTime? now,
  }) {
    if (items.isEmpty) {
      throw StateError('Cannot finalize a sale with no items');
    }
    final at = (now ?? DateTime.now()).toUtc();

    var subtotal = Money.zero;
    var vat = Money.zero;
    for (final item in items) {
      subtotal += item.lineTotal;
      vat += item.vatPortion;
    }
    final total = subtotal - billDiscount;
    var tendered = Money.zero;
    for (final tender in tenders) {
      tendered += tender.amount;
    }
    final due = tendered < total ? total - tendered : Money.zero;
    final paid = total - due;
    if (!due.isZero && customerId == null) {
      throw ArgumentError(
          'A sale with due (baki) must be attached to a customer');
    }

    return transaction(() async {
      final seq = await _nextSeqForDay(at);
      final sale = await into(sales).insertReturning(SalesCompanion.insert(
        invoiceNo: formatInvoiceNo(
            prefix: invoicePrefix, date: at, seq: seq, deviceNo: deviceNo),
        staffId: Value(staffId),
        customerId: Value(customerId),
        subtotal: subtotal,
        discount: Value(billDiscount),
        vat: Value(vat),
        total: total,
        paid: paid,
        due: Value(due),
        status: SaleStatus.finalized,
        createdAt: at,
      ));

      for (final item in items) {
        await into(saleItems).insert(SaleItemsCompanion.insert(
          saleId: sale.id,
          productId: Value(item.productId),
          nameSnapshot: item.nameSnapshot,
          qty: item.qty,
          unitPrice: item.unitPrice,
          lineDiscount: Value(item.lineDiscount),
          vatRateBp: Value(item.vatRateBp),
          lineTotal: item.lineTotal,
        ));
        if (item.productId != null) {
          await into(stockMovements).insert(StockMovementsCompanion.insert(
            productId: item.productId!,
            qtyDelta: -item.qty,
            type: MovementType.sale,
            refId: Value(sale.id),
            createdAt: Value(at),
          ));
        }
      }

      for (final tender in tenders) {
        await into(salePayments).insert(SalePaymentsCompanion.insert(
          saleId: sale.id,
          method: tender.method,
          amount: tender.amount,
          refNo: Value(tender.refNo),
        ));
      }

      return sale;
    });
  }

  Future<List<SaleItem>> itemsOf(String saleId) =>
      (select(saleItems)..where((i) => i.saleId.equals(saleId))).get();

  Future<List<SalePayment>> paymentsOf(String saleId) =>
      (select(salePayments)..where((p) => p.saleId.equals(saleId))).get();

  Stream<List<Sale>> watchSalesOn(DateTime day) {
    final start = DateTime.utc(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (select(sales)
          ..where((s) =>
              s.createdAt.isBiggerOrEqualValue(start) &
              s.createdAt.isSmallerThanValue(end))
          ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
        .watch();
  }

  Expression<bool> _inRange(DateTime start, DateTime end) =>
      sales.createdAt.isBiggerOrEqualValue(start) &
      sales.createdAt.isSmallerThanValue(end);

  /// Per-day sales totals in [start, end) — days without sales are omitted.
  Future<List<DailyTotal>> dailyTotals(
      {required DateTime start, required DateTime end}) async {
    final day = sales.createdAt.date;
    final total = sales.total.sum();
    final count = countAll();
    final query = selectOnly(sales)
      ..addColumns([day, total, count])
      ..where(_inRange(start, end))
      ..groupBy([day])
      ..orderBy([OrderingTerm.asc(day)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        DailyTotal(
          day: row.read(day)!,
          total: Money(row.read(total) ?? 0),
          count: row.read(count) ?? 0,
        ),
    ];
  }

  /// Products ranked by revenue in [start, end).
  Future<List<TopProduct>> topProducts(
      {required DateTime start, required DateTime end, int limit = 8}) async {
    final revenue = saleItems.lineTotal.sum();
    final qtySum = saleItems.qty.sum();
    final query = selectOnly(saleItems).join(
        [innerJoin(sales, sales.id.equalsExp(saleItems.saleId))])
      ..addColumns([saleItems.nameSnapshot, revenue, qtySum])
      ..where(_inRange(start, end))
      ..groupBy([saleItems.nameSnapshot])
      ..orderBy([OrderingTerm.desc(revenue)])
      ..limit(limit);
    final rows = await query.get();
    return [
      for (final row in rows)
        TopProduct(
          name: row.read(saleItems.nameSnapshot)!,
          qty: Qty(row.read(qtySum) ?? 0),
          revenue: Money(row.read(revenue) ?? 0),
        ),
    ];
  }

  /// Sales total per staff id in [start, end). A null key = sales with no
  /// attributed staff (recorded before login was enforced, or walk-in).
  Future<Map<String?, Money>> staffTotals(
      {required DateTime start, required DateTime end}) async {
    final total = sales.total.sum();
    final query = selectOnly(sales)
      ..addColumns([sales.staffId, total])
      ..where(_inRange(start, end))
      ..groupBy([sales.staffId]);
    final rows = await query.get();
    return {
      for (final row in rows)
        row.read(sales.staffId): Money(row.read(total) ?? 0),
    };
  }

  /// Tender totals per payment method in [start, end).
  Future<Map<PayMethod, Money>> paymentTotals(
      {required DateTime start, required DateTime end}) async {
    final amount = salePayments.amount.sum();
    final query = selectOnly(salePayments).join(
        [innerJoin(sales, sales.id.equalsExp(salePayments.saleId))])
      ..addColumns([salePayments.method, amount])
      ..where(_inRange(start, end))
      ..groupBy([salePayments.method]);
    final rows = await query.get();
    return {
      for (final row in rows)
        PayMethod.values.byName(row.read(salePayments.method)!):
            Money(row.read(amount) ?? 0),
    };
  }

  /// Sales are immutable and never deleted, so "count so far today + 1" is a
  /// stable daily sequence on a single device.
  Future<int> _nextSeqForDay(DateTime at) async {
    final start = DateTime.utc(at.year, at.month, at.day);
    final end = start.add(const Duration(days: 1));
    final count = countAll();
    final query = selectOnly(sales)
      ..addColumns([count])
      ..where(sales.createdAt.isBiggerOrEqualValue(start) &
          sales.createdAt.isSmallerThanValue(end));
    final row = await query.getSingle();
    return (row.read(count) ?? 0) + 1;
  }
}
