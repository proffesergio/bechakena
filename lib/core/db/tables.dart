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

class Categories extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get nameBn => text().nullable()();
  TextColumn get colorHex => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class Products extends Table with SyncColumns {
  TextColumn get barcode => text().nullable()();
  TextColumn get sku => text().nullable()();
  TextColumn get name => text()();
  TextColumn get nameBn => text().nullable()();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
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
}

/// Append-only. Current stock of a product = SUM(qtyDelta). Never store a
/// stock number anywhere else.
class StockMovements extends Table with SyncColumns {
  TextColumn get productId => text().references(Products, #id)();

  /// Branch/outlet this movement belongs to. Stock is derived per branch:
  /// stock(product, branch) = SUM(qtyDelta WHERE productId AND branchId).
  /// Nullable only for legacy rows (backfilled to the default branch on open).
  TextColumn get branchId => text().nullable().references(Shops, #id)();
  IntColumn get qtyDelta => integer().map(const QtyConverter())();
  TextColumn get type => textEnum<MovementType>()();

  /// Sale/purchase/return row this movement belongs to, if any.
  TextColumn get refId => text().nullable()();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
}

class Customers extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  BoolColumn get smsOptIn => boolean().withDefault(const Constant(true))();
}

/// Finalized sales are immutable — corrections happen via returns and
/// adjustments, never by editing these rows.
class Sales extends Table with SyncColumns {
  TextColumn get invoiceNo => text().unique()();

  /// Branch/outlet where the sale was rung up. Nullable only for legacy rows.
  TextColumn get branchId => text().nullable().references(Shops, #id)();
  TextColumn get staffId => text().nullable().references(Staff, #id)();
  TextColumn get customerId => text().nullable().references(Customers, #id)();
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

class SaleItems extends Table with SyncColumns {
  TextColumn get saleId => text().references(Sales, #id)();

  /// Null for manual (unlisted) items typed in at the POS.
  TextColumn get productId => text().nullable().references(Products, #id)();
  TextColumn get nameSnapshot => text()();
  IntColumn get qty => integer().map(const QtyConverter())();
  IntColumn get unitPrice => integer().map(const MoneyConverter())();
  IntColumn get lineDiscount =>
      integer().map(const MoneyConverter()).withDefault(const Constant(0))();
  IntColumn get vatRateBp => integer().withDefault(const Constant(0))();
  IntColumn get lineTotal => integer().map(const MoneyConverter())();
}

class SalePayments extends Table with SyncColumns {
  TextColumn get saleId => text().references(Sales, #id)();
  TextColumn get method => textEnum<PayMethod>()();
  IntColumn get amount => integer().map(const MoneyConverter())();
  TextColumn get refNo => text().nullable()();
}

/// Baki khata: payments received against a customer's due balance.
/// Balance = SUM(sales.due) − SUM(due_payments.amount) per customer.
class DuePayments extends Table with SyncColumns {
  TextColumn get customerId => text().references(Customers, #id)();
  IntColumn get amount => integer().map(const MoneyConverter())();
  TextColumn get method => textEnum<PayMethod>()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
}

/// A refund against a finalized (immutable) sale — the correction path.
/// Restocks via append-only saleReturn stock movements.
class Returns extends Table with SyncColumns {
  TextColumn get originalSaleId => text().nullable().references(Sales, #id)();
  TextColumn get staffId => text().nullable().references(Staff, #id)();
  IntColumn get refundTotal => integer().map(const MoneyConverter())();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
}

class ReturnItems extends Table with SyncColumns {
  TextColumn get returnId => text().references(Returns, #id)();
  TextColumn get productId => text().nullable().references(Products, #id)();
  TextColumn get nameSnapshot => text()();
  IntColumn get qty => integer().map(const QtyConverter())();
  IntColumn get refundAmount => integer().map(const MoneyConverter())();
}

class Suppliers extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
}

class Purchases extends Table with SyncColumns {
  /// Branch/outlet the stock was received into. Nullable only for legacy rows.
  TextColumn get branchId => text().nullable().references(Shops, #id)();
  TextColumn get supplierId => text().nullable().references(Suppliers, #id)();
  TextColumn get invoiceRef => text().nullable()();
  IntColumn get totalCost =>
      integer().map(const MoneyConverter()).withDefault(const Constant(0))();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
}

class PurchaseItems extends Table with SyncColumns {
  TextColumn get purchaseId => text().references(Purchases, #id)();
  TextColumn get productId => text().references(Products, #id)();
  IntColumn get qty => integer().map(const QtyConverter())();
  IntColumn get unitCost => integer().map(const MoneyConverter())();
  DateTimeColumn get expiryDate => dateTime().nullable()();
}

class SmsLog extends Table with SyncColumns {
  TextColumn get customerId => text().nullable().references(Customers, #id)();
  TextColumn get phone => text()();
  TextColumn get kind => textEnum<SmsKind>()();
  TextColumn get body => text()();
  TextColumn get status => textEnum<SmsStatus>()();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
}

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

/// Device-local key/value settings (locale, printer config, license blob…).
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
