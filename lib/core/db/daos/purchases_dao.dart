import 'package:drift/drift.dart';

import '../../money.dart';
import '../../qty.dart';
import '../database.dart';

part 'purchases_dao.g.dart';

/// One line of a purchase being entered.
class PurchaseDraftItem {
  const PurchaseDraftItem({
    required this.productId,
    required this.qty,
    required this.unitCost,
    this.expiryDate,
  });

  final String productId;
  final Qty qty;
  final Money unitCost;
  final DateTime? expiryDate;
}

@DriftAccessor(tables: [Purchases, PurchaseItems, StockMovements, Suppliers])
class PurchasesDao extends DatabaseAccessor<AppDatabase>
    with _$PurchasesDaoMixin {
  PurchasesDao(super.db);

  /// Records a purchase atomically: purchase row + items + restocking
  /// movements (with expiry dates for the expiring-soon alerts).
  Future<Purchase> createPurchase({
    String? supplierId,
    String? invoiceRef,
    required List<PurchaseDraftItem> items,
    DateTime? now,
  }) {
    if (items.isEmpty) {
      throw StateError('Cannot record a purchase with no items');
    }
    final at = (now ?? DateTime.now()).toUtc();
    var totalCost = Money.zero;
    for (final item in items) {
      totalCost += item.unitCost.timesQty(item.qty);
    }

    return transaction(() async {
      final purchase =
          await into(purchases).insertReturning(PurchasesCompanion.insert(
        supplierId: Value(supplierId),
        invoiceRef: Value(invoiceRef),
        totalCost: Value(totalCost),
        createdAt: Value(at),
      ));

      for (final item in items) {
        await into(purchaseItems).insert(PurchaseItemsCompanion.insert(
          purchaseId: purchase.id,
          productId: item.productId,
          qty: item.qty,
          unitCost: item.unitCost,
          expiryDate: Value(item.expiryDate),
        ));
        await into(stockMovements).insert(StockMovementsCompanion.insert(
          productId: item.productId,
          qtyDelta: item.qty,
          type: MovementType.purchase,
          refId: Value(purchase.id),
          expiryDate: Value(item.expiryDate),
          createdAt: Value(at),
        ));
      }
      return purchase;
    });
  }

  Future<List<PurchaseItem>> itemsOf(String purchaseId) =>
      (select(purchaseItems)..where((i) => i.purchaseId.equals(purchaseId)))
          .get();

  Stream<List<Purchase>> watchRecent({int limit = 100}) => (select(purchases)
        ..orderBy([(p) => OrderingTerm.desc(p.createdAt)])
        ..limit(limit))
      .watch();

  Future<Supplier> insertSupplier(SuppliersCompanion entry) =>
      into(suppliers).insertReturning(entry);

  Stream<List<Supplier>> watchSuppliers() => (select(suppliers)
        ..where((s) => s.deletedAt.isNull())
        ..orderBy([(s) => OrderingTerm.asc(s.name)]))
      .watch();
}
