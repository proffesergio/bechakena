import 'package:drift/drift.dart';

import '../../qty.dart';
import '../database.dart';

part 'stock_dao.g.dart';

/// A product whose derived stock is at or below its low-stock level.
class LowStockRow {
  const LowStockRow({required this.product, required this.stock});
  final Product product;
  final Qty stock;
}

/// A purchase batch with an expiry date that falls within the alert window.
class ExpiringBatch {
  const ExpiringBatch(
      {required this.product, required this.expiryDate, required this.qty});
  final Product product;
  final DateTime expiryDate;
  final Qty qty;
}

@DriftAccessor(tables: [StockMovements, Products])
class StockDao extends DatabaseAccessor<AppDatabase> with _$StockDaoMixin {
  StockDao(super.db);

  Future<StockMovement> addMovement({
    required String productId,
    required Qty qtyDelta,
    required MovementType type,
    String? refId,
    DateTime? expiryDate,
    String? note,
    DateTime? at,
    String? branchId,
  }) async {
    final branch = branchId ?? await attachedDatabase.currentBranchId();
    return into(stockMovements).insertReturning(StockMovementsCompanion.insert(
      productId: productId,
      branchId: Value(branch),
      qtyDelta: qtyDelta,
      type: type,
      refId: Value(refId),
      expiryDate: Value(expiryDate),
      note: Value(note),
      createdAt: at == null ? const Value.absent() : Value(at),
    ));
  }

  Expression<int> get _deltaSum => stockMovements.qtyDelta.sum();

  /// Derived-stock query, optionally scoped to one branch. A null [branchId]
  /// sums across all branches (used briefly before the current branch loads).
  JoinedSelectStatement<dynamic, dynamic> _stockQuery(String productId,
      {String? branchId}) {
    final where = branchId == null
        ? stockMovements.productId.equals(productId)
        : stockMovements.productId.equals(productId) &
            stockMovements.branchId.equals(branchId);
    return selectOnly(stockMovements)
      ..addColumns([_deltaSum])
      ..where(where);
  }

  /// Current stock — always derived, never stored (hard rule).
  Future<Qty> stockFor(String productId, {String? branchId}) async {
    final row = await _stockQuery(productId, branchId: branchId).getSingle();
    return Qty(row.read(_deltaSum) ?? 0);
  }

  Stream<Qty> watchStockFor(String productId, {String? branchId}) =>
      _stockQuery(productId, branchId: branchId)
          .watchSingle()
          .map((row) => Qty(row.read(_deltaSum) ?? 0));

  /// Active, stock-tracked products (lowStockLevel > 0) whose derived stock
  /// has fallen to or below that level. Stock stays derived — SUM of deltas.
  Future<List<LowStockRow>> lowStockProducts({String? branchId}) async {
    final stock = coalesce(
        [stockMovements.qtyDelta.sum(), const Constant<int>(0)]);
    // Scope the movement join to the branch so stock reflects this outlet.
    final joinOn = branchId == null
        ? stockMovements.productId.equalsExp(products.id)
        : stockMovements.productId.equalsExp(products.id) &
            stockMovements.branchId.equals(branchId);
    final query = select(products).join([
      leftOuterJoin(stockMovements, joinOn),
    ])
      ..where(products.deletedAt.isNull() &
          products.isActive.equals(true) &
          products.lowStockLevel.isBiggerThanValue(0))
      ..addColumns([stock])
      ..groupBy([products.id],
          having: stock.isSmallerOrEqual(products.lowStockLevel))
      ..orderBy([OrderingTerm.asc(stock)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        LowStockRow(
          product: row.readTable(products),
          stock: Qty(row.read(stock) ?? 0),
        ),
    ];
  }

  /// Purchase batches expiring on or before now + [within] (already-expired
  /// batches included), soonest first.
  Future<List<ExpiringBatch>> expiringSoon(
      {required Duration within, DateTime? now, String? branchId}) async {
    final cutoff = (now ?? DateTime.now().toUtc()).add(within);
    final branchFilter = branchId == null
        ? const Constant(true)
        : stockMovements.branchId.equals(branchId);
    final query = select(stockMovements).join([
      innerJoin(products, products.id.equalsExp(stockMovements.productId)),
    ])
      ..where(stockMovements.expiryDate.isNotNull() &
          stockMovements.expiryDate.isSmallerOrEqualValue(cutoff) &
          branchFilter &
          products.deletedAt.isNull())
      ..orderBy([OrderingTerm.asc(stockMovements.expiryDate)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        ExpiringBatch(
          product: row.readTable(products),
          // Drift returns local DateTimes; normalize to UTC (storage contract).
          expiryDate: row.readTable(stockMovements).expiryDate!.toUtc(),
          qty: row.readTable(stockMovements).qtyDelta,
        ),
    ];
  }
}
