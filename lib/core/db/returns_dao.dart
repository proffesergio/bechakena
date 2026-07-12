import 'package:drift/drift.dart';

import '../money.dart';
import '../qty.dart';
import 'database.dart';

part 'returns_dao.g.dart';

/// One line of a return being entered at the POS.
class ReturnDraftItem {
  const ReturnDraftItem({
    this.productId,
    required this.nameSnapshot,
    required this.qty,
    required this.refundAmount,
  });

  /// Null for manual (unlisted) items — no stock movement is written.
  final String? productId;
  final String nameSnapshot;
  final Qty qty;
  final Money refundAmount;
}

@DriftAccessor(tables: [Returns, ReturnItems, StockMovements])
class ReturnsDao extends DatabaseAccessor<AppDatabase> with _$ReturnsDaoMixin {
  ReturnsDao(super.db);

  /// Records a refund atomically: return row + items + restocking movements.
  /// The original sale is never modified (finalized sales are immutable).
  Future<Return> createReturn({
    String? originalSaleId,
    String? staffId,
    required List<ReturnDraftItem> items,
    String? note,
    DateTime? now,
  }) {
    if (items.isEmpty) {
      throw StateError('Cannot record a return with no items');
    }
    final at = (now ?? DateTime.now()).toUtc();
    var refundTotal = Money.zero;
    for (final item in items) {
      refundTotal += item.refundAmount;
    }

    return transaction(() async {
      final ret = await into(returns).insertReturning(ReturnsCompanion.insert(
        originalSaleId: Value(originalSaleId),
        staffId: Value(staffId),
        refundTotal: refundTotal,
        note: Value(note),
        createdAt: Value(at),
      ));

      for (final item in items) {
        await into(returnItems).insert(ReturnItemsCompanion.insert(
          returnId: ret.id,
          productId: Value(item.productId),
          nameSnapshot: item.nameSnapshot,
          qty: item.qty,
          refundAmount: item.refundAmount,
        ));
        if (item.productId != null) {
          await into(stockMovements).insert(StockMovementsCompanion.insert(
            productId: item.productId!,
            qtyDelta: item.qty, // positive: restock
            type: MovementType.saleReturn,
            refId: Value(ret.id),
            createdAt: Value(at),
          ));
        }
      }
      return ret;
    });
  }

  Future<List<ReturnItem>> itemsOf(String returnId) =>
      (select(returnItems)..where((i) => i.returnId.equals(returnId))).get();

  Stream<List<Return>> watchRecent({int limit = 100}) => (select(returns)
        ..orderBy([(r) => OrderingTerm.desc(r.createdAt)])
        ..limit(limit))
      .watch();

  /// Total refunded in [start, end).
  Future<Money> refundsInRange(
      {required DateTime start, required DateTime end}) async {
    final sum = returns.refundTotal.sum();
    final query = selectOnly(returns)
      ..addColumns([sum])
      ..where(returns.createdAt.isBiggerOrEqualValue(start) &
          returns.createdAt.isSmallerThanValue(end));
    final row = await query.getSingle();
    return Money(row.read(sum) ?? 0);
  }
}
