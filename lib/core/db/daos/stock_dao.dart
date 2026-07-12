import 'package:drift/drift.dart';

import '../../qty.dart';
import '../database.dart';

part 'stock_dao.g.dart';

@DriftAccessor(tables: [StockMovements])
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
  }) =>
      into(stockMovements).insertReturning(StockMovementsCompanion.insert(
        productId: productId,
        qtyDelta: qtyDelta,
        type: type,
        refId: Value(refId),
        expiryDate: Value(expiryDate),
        note: Value(note),
        createdAt: at == null ? const Value.absent() : Value(at),
      ));

  Expression<int> get _deltaSum => stockMovements.qtyDelta.sum();

  JoinedSelectStatement<dynamic, dynamic> _stockQuery(String productId) {
    return selectOnly(stockMovements)
      ..addColumns([_deltaSum])
      ..where(stockMovements.productId.equals(productId));
  }

  /// Current stock — always derived, never stored (hard rule).
  Future<Qty> stockFor(String productId) async {
    final row = await _stockQuery(productId).getSingle();
    return Qty(row.read(_deltaSum) ?? 0);
  }

  Stream<Qty> watchStockFor(String productId) => _stockQuery(productId)
      .watchSingle()
      .map((row) => Qty(row.read(_deltaSum) ?? 0));
}
