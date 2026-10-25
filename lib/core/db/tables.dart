import 'package:drift/drift.dart';

import '../ids.dart';
import 'converters.dart';

/// Sync contract (docs/DESIGN.md §3.1): every synced row carries a UUIDv7
/// primary key, updatedAt, soft-delete marker and the writing device's id.
mixin SyncColumns on Table {
  TextColumn get id => text().clientDefault(newUuidV7)();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get deviceId => text().clientDefault(() => currentDeviceId)();

  @override
  Set<Column> get primaryKey => {id};
}

enum MovementType { purchase, sale, adjustment, saleReturn }

enum PayMethod { cash, bkash, nagad, card }

enum SaleStatus { draft, finalized }

enum StaffRole { owner, manager, cashier }

enum SmsKind { receipt, dueReminder }

enum SmsStatus { queued, sent, failed }

/// How a restaurant order is served. Dine-in orders attach to a [DiningTables]
/// row; takeaway/delivery orders carry a customer name instead.
enum OrderType { dineIn, takeaway, delivery }

/// Lifecycle of a restaurant order. Open orders are the running tabs; settling
/// converts one into an immutable finalized [Sales] row; cancelling voids it.
enum OrderStatus { open, settled, cancelled }

// ─── Shop organisation ────────────────────────────────────────────────────

class Shops extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get nameBn => text().nullable()();
  TextColumn get logoPath => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get phone => text().nullable()();
  IntColumn get vatRateBp => integer().withDefault(const Constant(0))();
  TextColumn get receiptFooter => text().nullable()();
  TextColumn get invoicePrefix => text().withDefault(const Constant('BK'))();
}

class Staff extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get pinHash => text()();
  TextColumn get role => textEnum<StaffRole>()();
}

// ─── Catalog & inventory ──────────────────────────────────────────────────

class Categories extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get nameBn => text().nullable()();
  TextColumn get colorHex => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// 'superShop' or 'restaurant' — keeps each module's categories separate.
  TextColumn get businessType =>
      text().withDefault(const Constant('superShop'))();
}

@TableIndex(name: 'idx_products_category_id', columns: {#categoryId})
class Products extends Table with SyncColumns {
  TextColumn get barcode => text().nullable()();
  TextColumn get sku => text().nullable()();
  TextColumn get name => text()();
  TextColumn get nameBn => text().nullable()();
  TextColumn get categoryId => text().nullable().references(Categories, #id, onDelete: KeyAction.restrict)();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  IntColumn get salePrice => integer().map(const MoneyConverter())();
  IntColumn get costPrice =>
      integer().map(const MoneyConverter()).withDefault(const Constant(0))();

  /// VAT contained in salePrice, in basis points (15% = 1500). Prices are
  /// always VAT-inclusive.
  IntColumn get vatRateBp => integer().withDefault(const Constant(0))();
  IntColumn get lowStockLevel =>
      integer().map(const QtyConverter()).withDefault(const Constant(0))();
  TextColumn get imagePath => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Which module owns this item: 'superShop' or 'restaurant'. Keeps the retail
  /// catalog and the restaurant menu separate on the same install.
  TextColumn get businessType =>
      text().withDefault(const Constant('superShop'))();
}

/// Append-only. Current stock of a product = SUM(qtyDelta). Never store a
/// stock number anywhere else.
@TableIndex(name: 'idx_stock_movements_product_id', columns: {#productId})
@TableIndex(
  name: 'idx_stock_movements_branch_product',
  columns: {#branchId, #productId},
)
class StockMovements extends Table with SyncColumns {
  TextColumn get productId => text().references(Products, #id, onDelete: KeyAction.restrict)();

  /// Branch/outlet this movement belongs to. Stock is derived per branch:
  /// stock(product, branch) = SUM(qtyDelta WHERE productId AND branchId).
  /// Nullable only for legacy rows (backfilled to the default branch on open).
  TextColumn get branchId => text().nullable().references(Shops, #id, onDelete: KeyAction.restrict)();
  IntColumn get qtyDelta => integer().map(const QtyConverter())();
  TextColumn get type => textEnum<MovementType>()();

  /// Sale/purchase/return row this movement belongs to, if any.
  TextColumn get refId => text().nullable()();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
}

// ─── Customers, sales & baki ──────────────────────────────────────────────

class Customers extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  BoolColumn get smsOptIn => boolean().withDefault(const Constant(true))();
}

/// Finalized sales are immutable — corrections happen via returns and
/// adjustments, never by editing these rows.
@TableIndex(name: 'idx_sales_branch_created', columns: {#branchId, #createdAt})
@TableIndex(name: 'idx_sales_customer_id', columns: {#customerId})
@TableIndex(name: 'idx_sales_staff_id', columns: {#staffId})
class Sales extends Table with SyncColumns {
  TextColumn get invoiceNo => text().unique()();

  /// Branch/outlet where the sale was rung up. Nullable only for legacy rows.
  TextColumn get branchId => text().nullable().references(Shops, #id, onDelete: KeyAction.restrict)();
  TextColumn get staffId => text().nullable().references(Staff, #id, onDelete: KeyAction.restrict)();
  TextColumn get customerId => text().nullable().references(Customers, #id, onDelete: KeyAction.restrict)();
  IntColumn get subtotal => integer().map(const MoneyConverter())();
  IntColumn get discount =>
      integer().map(const MoneyConverter()).withDefault(const Constant(0))();
  IntColumn get vat =>
      integer().map(const MoneyConverter()).withDefault(const Constant(0))();
  IntColumn get total => integer().map(const MoneyConverter())();
  IntColumn get paid => integer().map(const MoneyConverter())();
  IntColumn get due =>
      integer().map(const MoneyConverter()).withDefault(const Constant(0))();
  TextColumn get status => textEnum<SaleStatus>()();
  DateTimeColumn get createdAt => dateTime()();
}

@TableIndex(name: 'idx_sale_items_product_id', columns: {#productId})
@TableIndex(name: 'idx_sale_items_sale_id', columns: {#saleId})
class SaleItems extends Table with SyncColumns {
  TextColumn get saleId => text().references(Sales, #id, onDelete: KeyAction.restrict)();

  /// Null for manual (unlisted) items typed in at the POS.
  TextColumn get productId => text().nullable().references(Products, #id, onDelete: KeyAction.restrict)();
  TextColumn get nameSnapshot => text()();
  IntColumn get qty => integer().map(const QtyConverter())();
  IntColumn get unitPrice => integer().map(const MoneyConverter())();
  IntColumn get lineDiscount =>
      integer().map(const MoneyConverter()).withDefault(const Constant(0))();
  IntColumn get vatRateBp => integer().withDefault(const Constant(0))();
  IntColumn get lineTotal => integer().map(const MoneyConverter())();
}

@TableIndex(name: 'idx_sale_payments_sale_id', columns: {#saleId})
class SalePayments extends Table with SyncColumns {
  TextColumn get saleId => text().references(Sales, #id, onDelete: KeyAction.restrict)();
  TextColumn get method => textEnum<PayMethod>()();
  IntColumn get amount => integer().map(const MoneyConverter())();
  TextColumn get refNo => text().nullable()();
}

/// Baki khata: payments received against a customer's due balance.
/// Balance = SUM(sales.due) − SUM(due_payments.amount) per customer.
@TableIndex(name: 'idx_due_payments_customer_id', columns: {#customerId})
class DuePayments extends Table with SyncColumns {
  TextColumn get customerId => text().references(Customers, #id, onDelete: KeyAction.restrict)();
  IntColumn get amount => integer().map(const MoneyConverter())();
  TextColumn get method => textEnum<PayMethod>()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
}

/// A refund against a finalized (immutable) sale — the correction path.
/// Restocks via append-only saleReturn stock movements.
@TableIndex(name: 'idx_returns_original_sale_id', columns: {#originalSaleId})
@TableIndex(name: 'idx_returns_staff_id', columns: {#staffId})
class Returns extends Table with SyncColumns {
  TextColumn get originalSaleId => text().nullable().references(Sales, #id, onDelete: KeyAction.restrict)();
  TextColumn get staffId => text().nullable().references(Staff, #id, onDelete: KeyAction.restrict)();
  IntColumn get refundTotal => integer().map(const MoneyConverter())();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
}

@TableIndex(name: 'idx_return_items_return_id', columns: {#returnId})
@TableIndex(name: 'idx_return_items_product_id', columns: {#productId})
class ReturnItems extends Table with SyncColumns {
  TextColumn get returnId => text().references(Returns, #id, onDelete: KeyAction.restrict)();
  TextColumn get productId => text().nullable().references(Products, #id, onDelete: KeyAction.restrict)();
  TextColumn get nameSnapshot => text()();
  IntColumn get qty => integer().map(const QtyConverter())();
  IntColumn get refundAmount => integer().map(const MoneyConverter())();
}

// ─── Purchasing ───────────────────────────────────────────────────────────

class Suppliers extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
}

@TableIndex(
  name: 'idx_purchases_branch_created',
  columns: {#branchId, #createdAt},
)
@TableIndex(name: 'idx_purchases_supplier_id', columns: {#supplierId})
class Purchases extends Table with SyncColumns {
  /// Branch/outlet the stock was received into. Nullable only for legacy rows.
  TextColumn get branchId => text().nullable().references(Shops, #id, onDelete: KeyAction.restrict)();
  TextColumn get supplierId => text().nullable().references(Suppliers, #id, onDelete: KeyAction.restrict)();
  TextColumn get invoiceRef => text().nullable()();
  IntColumn get totalCost =>
      integer().map(const MoneyConverter()).withDefault(const Constant(0))();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
}

@TableIndex(name: 'idx_purchase_items_product_id', columns: {#productId})
@TableIndex(name: 'idx_purchase_items_purchase_id', columns: {#purchaseId})
class PurchaseItems extends Table with SyncColumns {
  TextColumn get purchaseId => text().references(Purchases, #id, onDelete: KeyAction.restrict)();
  TextColumn get productId => text().references(Products, #id, onDelete: KeyAction.restrict)();
  IntColumn get qty => integer().map(const QtyConverter())();
  IntColumn get unitCost => integer().map(const MoneyConverter())();
  DateTimeColumn get expiryDate => dateTime().nullable()();
}

// ─── Messaging ────────────────────────────────────────────────────────────

@TableIndex(name: 'idx_sms_log_customer_id', columns: {#customerId})
class SmsLog extends Table with SyncColumns {
  TextColumn get customerId => text().nullable().references(Customers, #id, onDelete: KeyAction.restrict)();
  TextColumn get phone => text()();
  TextColumn get kind => textEnum<SmsKind>()();
  TextColumn get body => text()();
  TextColumn get status => textEnum<SmsStatus>()();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
}

// ─── Sync & device-local ─────────────────────────────────────────────────

/// Local outbox for the sync engine — device-local, not itself synced.
class SyncOutbox extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get targetTable => text().named('table_name')();
  TextColumn get rowId => text()();
  TextColumn get op => text()();
  TextColumn get payload => text()();
  DateTimeColumn get queuedAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
}

// ─── Restaurant module (dining) ────────────────────────────────────────────

/// Restaurant mode: dining tables/seats an order can be attached to. Only used
/// when the business type is restaurant; harmless (empty) otherwise.
class DiningTables extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get area => text().nullable()();
  IntColumn get seats => integer().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

/// Restaurant mode: a running order (tab). Dine-in orders point at a table;
/// takeaway/delivery orders carry a customer name. Stays `open` while items are
/// being added; settling stamps [saleId] with the finalized sale it became.
@TableIndex(name: 'idx_dine_orders_table_id', columns: {#tableId})
@TableIndex(
  name: 'idx_dine_orders_branch_status',
  columns: {#branchId, #status},
)
@TableIndex(name: 'idx_dine_orders_staff_id', columns: {#staffId})
@TableIndex(name: 'idx_dine_orders_sale_id', columns: {#saleId})
class DineOrders extends Table with SyncColumns {
  TextColumn get tableId => text().nullable().references(DiningTables, #id, onDelete: KeyAction.restrict)();
  TextColumn get orderType => textEnum<OrderType>()();
  TextColumn get status =>
      textEnum<OrderStatus>().withDefault(const Constant('open'))();

  /// Branch/outlet the order was opened in. Nullable only for legacy rows.
  TextColumn get branchId => text().nullable().references(Shops, #id, onDelete: KeyAction.restrict)();
  TextColumn get staffId => text().nullable().references(Staff, #id, onDelete: KeyAction.restrict)();

  /// For takeaway/delivery (dine-in identifies the guest by the table).
  TextColumn get customerName => text().nullable()();
  TextColumn get customerPhone => text().nullable()();
  TextColumn get note => text().nullable()();

  /// The finalized sale this order became on settle; null while open.
  TextColumn get saleId => text().nullable().references(Sales, #id, onDelete: KeyAction.restrict)();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
}

/// A line on a running restaurant order. Mirrors a cart line but is persisted so
/// tabs survive navigation and restarts. `kotSent` tracks which lines have been
/// fired to the kitchen so a re-print only sends the new ones.
@TableIndex(name: 'idx_order_items_product_id', columns: {#productId})
@TableIndex(name: 'idx_order_items_order_id', columns: {#orderId})
class DineOrderItems extends Table with SyncColumns {
  TextColumn get orderId => text().references(DineOrders, #id, onDelete: KeyAction.restrict)();

  /// Null for manual (off-menu) items typed in at the table.
  TextColumn get productId => text().nullable().references(Products, #id, onDelete: KeyAction.restrict)();
  TextColumn get nameSnapshot => text()();
  IntColumn get qty => integer().map(const QtyConverter())();
  IntColumn get unitPrice => integer().map(const MoneyConverter())();
  IntColumn get vatRateBp => integer().withDefault(const Constant(0))();
  TextColumn get note => text().nullable()();
  BoolColumn get kotSent => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
}

/// Device-local key/value settings (locale, printer config, license blob…).
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
