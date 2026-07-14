import 'package:drift/drift.dart';

import '../../money.dart';
import '../../qty.dart';
import '../database.dart';
import '../sale_draft.dart';

part 'orders_dao.g.dart';

/// Restaurant running orders (tabs). An order stays `open` while items are added
/// at the table/counter; [settleOrder] converts it into an immutable finalized
/// [Sales] row (reusing the same engine as the retail POS), so restaurant sales
/// flow into history, reports and per-branch stock exactly like retail ones.
@DriftAccessor(tables: [DineOrders, DineOrderItems])
class OrdersDao extends DatabaseAccessor<AppDatabase> with _$OrdersDaoMixin {
  OrdersDao(super.db);

  /// All open tabs, oldest first. Optionally filtered to one order type.
  Stream<List<DineOrder>> watchOpenOrders({OrderType? type}) {
    final q = select(dineOrders)
      ..where((o) => o.status.equalsValue(OrderStatus.open))
      ..where((o) => o.deletedAt.isNull())
      ..orderBy([(o) => OrderingTerm.asc(o.createdAt)]);
    if (type != null) q.where((o) => o.orderType.equalsValue(type));
    return q.watch();
  }

  /// The open order sitting on a table, if any (drives free/occupied status).
  Future<DineOrder?> openOrderForTable(String tableId) => (select(dineOrders)
        ..where((o) => o.tableId.equals(tableId))
        ..where((o) => o.status.equalsValue(OrderStatus.open))
        ..where((o) => o.deletedAt.isNull())
        ..limit(1))
      .getSingleOrNull();

  Future<DineOrder?> byId(String orderId) =>
      (select(dineOrders)..where((o) => o.id.equals(orderId)))
          .getSingleOrNull();

  /// Opens a new tab. For dine-in pass [tableId]; for takeaway/delivery pass a
  /// [customerName]. Branch defaults to this device's current branch.
  Future<DineOrder> createOrder({
    String? tableId,
    required OrderType orderType,
    String? staffId,
    String? branchId,
    String? customerName,
    String? customerPhone,
  }) async {
    final branch = branchId ?? await attachedDatabase.currentBranchId();
    return into(dineOrders).insertReturning(DineOrdersCompanion.insert(
      tableId: Value(tableId),
      orderType: orderType,
      branchId: Value(branch),
      staffId: Value(staffId),
      customerName: Value(customerName),
      customerPhone: Value(customerPhone),
    ));
  }

  Stream<List<DineOrderItem>> watchItems(String orderId) => (select(dineOrderItems)
        ..where((i) => i.orderId.equals(orderId))
        ..where((i) => i.deletedAt.isNull())
        ..orderBy([(i) => OrderingTerm.asc(i.createdAt)]))
      .watch();

  Future<List<DineOrderItem>> itemsOf(String orderId) => (select(dineOrderItems)
        ..where((i) => i.orderId.equals(orderId))
        ..where((i) => i.deletedAt.isNull()))
      .get();

  /// Adds a menu product to the tab. Merges into an existing line for the same
  /// product only while that line has not yet been fired to the kitchen — once
  /// sent, a fresh addition becomes its own (unsent) line so the KOT delta stays
  /// correct.
  Future<void> addProduct(String orderId, Product product,
      {Qty qty = const Qty(1000)}) async {
    final existing = await (select(dineOrderItems)
          ..where((i) => i.orderId.equals(orderId))
          ..where((i) => i.productId.equals(product.id))
          ..where((i) => i.kotSent.equals(false))
          ..where((i) => i.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) {
      await setQty(existing.id, existing.qty + qty);
      return;
    }
    await into(dineOrderItems).insert(DineOrderItemsCompanion.insert(
      orderId: orderId,
      productId: Value(product.id),
      nameSnapshot: product.name,
      qty: qty,
      unitPrice: product.salePrice,
      vatRateBp: Value(product.vatRateBp),
    ));
  }

  /// Adds an off-menu item typed in by the waiter.
  Future<void> addManual(String orderId,
          {required String name,
          required Money price,
          Qty qty = const Qty(1000)}) =>
      into(dineOrderItems).insert(DineOrderItemsCompanion.insert(
        orderId: orderId,
        nameSnapshot: name,
        qty: qty,
        unitPrice: price,
      ));

  Future<void> setQty(String itemId, Qty qty) async {
    if (qty <= Qty.zero) {
      await removeItem(itemId);
      return;
    }
    await (update(dineOrderItems)..where((i) => i.id.equals(itemId))).write(
        DineOrderItemsCompanion(
            qty: Value(qty), updatedAt: Value(DateTime.now().toUtc())));
  }

  Future<void> removeItem(String itemId) =>
      (update(dineOrderItems)..where((i) => i.id.equals(itemId))).write(
          DineOrderItemsCompanion(
              deletedAt: Value(DateTime.now().toUtc()),
              updatedAt: Value(DateTime.now().toUtc())));

  /// Lines not yet fired to the kitchen — the payload of the next KOT.
  Future<List<DineOrderItem>> unsentItems(String orderId) =>
      (select(dineOrderItems)
            ..where((i) => i.orderId.equals(orderId))
            ..where((i) => i.kotSent.equals(false))
            ..where((i) => i.deletedAt.isNull())
            ..orderBy([(i) => OrderingTerm.asc(i.createdAt)]))
          .get();

  /// Marks every currently-unsent line as fired (call after printing the KOT).
  Future<void> markKotSent(String orderId) =>
      (update(dineOrderItems)..where((i) =>
              i.orderId.equals(orderId) &
              i.kotSent.equals(false) &
              i.deletedAt.isNull()))
          .write(DineOrderItemsCompanion(
              kotSent: const Value(true),
              updatedAt: Value(DateTime.now().toUtc())));

  /// Voids an open tab (nothing was sold — no stock/sale side effects).
  Future<void> cancelOrder(String orderId) =>
      (update(dineOrders)..where((o) => o.id.equals(orderId))).write(
          DineOrdersCompanion(
              status: const Value(OrderStatus.cancelled),
              deletedAt: Value(DateTime.now().toUtc()),
              updatedAt: Value(DateTime.now().toUtc())));

  /// Settles an open order into a finalized, immutable sale: writes the sale +
  /// items + payments + stock movements (via [SalesDao.finalizeSale]) and stamps
  /// the order `settled` with the resulting sale id. The table frees up
  /// automatically (no more open order references it).
  Future<Sale> settleOrder({
    required String orderId,
    required List<TenderDraft> tenders,
    String? customerId,
    Money billDiscount = Money.zero,
    String invoicePrefix = 'BK',
  }) async {
    final order = await byId(orderId);
    if (order == null) throw StateError('Order $orderId not found');
    if (order.status != OrderStatus.open) {
      throw StateError('Order $orderId is not open');
    }
    final items = await itemsOf(orderId);
    if (items.isEmpty) {
      throw StateError('Cannot settle an order with no items');
    }
    final drafts = [
      for (final i in items)
        SaleDraftItem(
          productId: i.productId,
          nameSnapshot: i.nameSnapshot,
          qty: i.qty,
          unitPrice: i.unitPrice,
          vatRateBp: i.vatRateBp,
        ),
    ];
    return transaction(() async {
      final sale = await attachedDatabase.salesDao.finalizeSale(
        invoicePrefix: invoicePrefix,
        staffId: order.staffId,
        customerId: customerId,
        items: drafts,
        tenders: tenders,
        billDiscount: billDiscount,
        branchId: order.branchId,
      );
      await (update(dineOrders)..where((o) => o.id.equals(orderId))).write(
          DineOrdersCompanion(
              status: const Value(OrderStatus.settled),
              saleId: Value(sale.id),
              updatedAt: Value(DateTime.now().toUtc())));
      return sale;
    });
  }
}
