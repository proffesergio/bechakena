import 'package:drift/drift.dart';

import '../../sales/sale_finalizer.dart';
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
    String? branchId,
  }) => SaleFinalizer(attachedDatabase).finalize(
      invoicePrefix: invoicePrefix, deviceNo: deviceNo, staffId: staffId,
      customerId: customerId, items: items, tenders: tenders,
      billDiscount: billDiscount, now: now, branchId: branchId);

  Future<Sale?> byId(String saleId, {String? branchId}) => (select(sales)
        ..where((s) => s.id.equals(saleId) & s.deletedAt.isNull() & _branchFilter(branchId)))
      .getSingleOrNull();

  Future<Sale?> findByInvoiceNo(String invoiceNo, {String? branchId}) => (select(sales)
        ..where((s) => s.invoiceNo.equals(invoiceNo) & s.deletedAt.isNull() & _branchFilter(branchId)))
      .getSingleOrNull();

  Future<List<SaleItem>> itemsOf(String saleId, {String? branchId}) => (select(saleItems)
        ..where((i) => i.saleId.equals(saleId) & i.deletedAt.isNull() & _readableSale(i.saleId, branchId)))
      .get();

  Future<List<SalePayment>> paymentsOf(String saleId, {String? branchId}) => (select(salePayments)
        ..where((p) => p.saleId.equals(saleId) & p.deletedAt.isNull() & _readableSale(p.saleId, branchId)))
      .get();

  /// Recent sales, newest first. [branchId] scopes the list to one outlet
  /// (staff read scope); null means every branch (owner / head office).
  Stream<List<Sale>> watchRecent({int limit = 100, String? branchId}) =>
      (select(sales)
        ..where((s) =>
            s.deletedAt.isNull() &
            (branchId == null
                ? const Constant(true)
                : s.branchId.equals(branchId)))
        ..orderBy([(s) => OrderingTerm.desc(s.createdAt)])
        ..limit(limit))
      .watch();

  Expression<bool> _readableSale(Expression<String> id, String? branchId) =>
      existsQuery(selectOnly(sales)..addColumns([sales.id])
        ..where(sales.id.equalsExp(id) & sales.deletedAt.isNull() & _branchFilter(branchId)));

  Expression<bool> _branchFilter(String? branchId) => branchId == null
      ? const Constant(true) : sales.branchId.equals(branchId);

  Expression<bool> _inRange(DateTime start, DateTime end, String? branchId) =>
      sales.createdAt.isBiggerOrEqualValue(start) &
      sales.createdAt.isSmallerThanValue(end) &
      sales.deletedAt.isNull() & _branchFilter(branchId);

  /// Per-day sales totals in [start, end) — days without sales are omitted.
  Future<List<DailyTotal>> dailyTotals(
      {required DateTime start, required DateTime end, String? branchId}) async {
    final day = sales.createdAt.date;
    final total = sales.total.sum();
    final count = countAll();
    final query = selectOnly(sales)
      ..addColumns([day, total, count])
      ..where(_inRange(start, end, branchId))
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
      {required DateTime start, required DateTime end, int limit = 8, String? branchId}) async {
    final revenue = saleItems.lineTotal.sum();
    final qtySum = saleItems.qty.sum();
    final query = selectOnly(saleItems).join(
        [innerJoin(sales, sales.id.equalsExp(saleItems.saleId))])
      ..addColumns([saleItems.nameSnapshot, revenue, qtySum])
      ..where(_inRange(start, end, branchId) & saleItems.deletedAt.isNull())
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
      {required DateTime start, required DateTime end, String? branchId}) async {
    final total = sales.total.sum();
    final query = selectOnly(sales)
      ..addColumns([sales.staffId, total])
      ..where(_inRange(start, end, branchId))
      ..groupBy([sales.staffId]);
    final rows = await query.get();
    return {
      for (final row in rows)
        row.read(sales.staffId): Money(row.read(total) ?? 0),
    };
  }

  /// Tender totals per payment method in [start, end).
  Future<Map<PayMethod, Money>> paymentTotals(
      {required DateTime start, required DateTime end, String? branchId}) async {
    final amount = salePayments.amount.sum();
    final query = selectOnly(salePayments).join(
        [innerJoin(sales, sales.id.equalsExp(salePayments.saleId))])
      ..addColumns([salePayments.method, amount])
      ..where(_inRange(start, end, branchId))
      ..groupBy([salePayments.method]);
    final rows = await query.get();
    return {
      for (final row in rows)
        PayMethod.values.byName(row.read(salePayments.method)!):
            Money(row.read(amount) ?? 0),
    };
  }

}
