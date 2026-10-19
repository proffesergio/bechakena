import 'package:drift/drift.dart';

import '../ids.dart';
import '../money.dart';
import '../qty.dart';
import 'converters.dart';
import 'daos/customers_dao.dart';
import 'daos/products_dao.dart';
import 'daos/purchases_dao.dart';
import 'daos/sales_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/sms_dao.dart';
import 'daos/orders_dao.dart';
import 'daos/staff_dao.dart';
import 'daos/stock_dao.dart';
import 'returns_dao.dart';
import 'tables.dart';

export 'daos/customers_dao.dart';
export 'daos/products_dao.dart';
export 'daos/purchases_dao.dart';
export 'daos/sales_dao.dart';
export 'daos/settings_dao.dart';
export 'daos/sms_dao.dart';
export 'daos/orders_dao.dart';
export 'daos/staff_dao.dart';
export 'daos/stock_dao.dart';
export 'returns_dao.dart';
export 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Shops,
    Staff,
    Categories,
    Products,
    StockMovements,
    Customers,
    Sales,
    SaleItems,
    SalePayments,
    DuePayments,
    Suppliers,
    Purchases,
    PurchaseItems,
    SmsLog,
    SyncOutbox,
    Settings,
    Returns,
    ReturnItems,
    DiningTables,
    DineOrders,
    DineOrderItems,
  ],
  daos: [
    ProductsDao,
    StockDao,
    SalesDao,
    CustomersDao,
    PurchasesDao,
    SettingsDao,
    StaffDao,
    ReturnsDao,
    SmsDao,
    OrdersDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v2 adds the returns tables (immutable-sale correction path).
      if (from < 2) {
        await m.createTable(returns);
        await m.createTable(returnItems);
      }
      // v3 adds the multi-branch dimension. Columns are nullable so the
      // add succeeds on existing rows; _bootstrapBranch() then backfills
      // them to the default branch on this same open.
      if (from < 3) {
        await m.addColumn(stockMovements, stockMovements.branchId);
        await m.addColumn(sales, sales.branchId);
        await m.addColumn(purchases, purchases.branchId);
      }
      // v4 adds restaurant-mode dining tables.
      if (from < 4) {
        await m.createTable(diningTables);
      }
      // v5 tags catalog rows with a business type so supershop and
      // restaurant have separate catalogs. Existing rows default to
      // 'superShop' via the column default.
      if (from < 5) {
        await m.addColumn(products, products.businessType);
        await m.addColumn(categories, categories.businessType);
      }
      // v6 adds restaurant running orders (dine-in / takeaway / delivery)
      // and their line items.
      if (from < 6) {
        await m.createTable(dineOrders);
        await m.createTable(dineOrderItems);
      }
      // v7 adds indexes on the hot product_id foreign keys used by stock
      // derivation, analytics and menu reports (audit finding 4.1-4.4).
      if (from < 7) {
        await m.createIndex(idxStockMovementsProductId);
        await m.createIndex(idxSaleItemsProductId);
        await m.createIndex(idxPurchaseItemsProductId);
        await m.createIndex(idxOrderItemsProductId);
      }
      // v8 covers every remaining foreign key and branch hot path.
      if (from < 8) {
        for (final index in [
          idxProductsCategoryId,
          idxStockMovementsBranchProduct,
          idxSalesBranchCreated,
          idxSalesCustomerId,
          idxSalesStaffId,
          idxSaleItemsSaleId,
          idxSalePaymentsSaleId,
          idxDuePaymentsCustomerId,
          idxReturnsOriginalSaleId,
          idxReturnsStaffId,
          idxReturnItemsReturnId,
          idxReturnItemsProductId,
          idxPurchasesBranchCreated,
          idxPurchasesSupplierId,
          idxPurchaseItemsPurchaseId,
          idxSmsLogCustomerId,
          idxDineOrdersTableId,
          idxDineOrdersBranchStatus,
          idxDineOrdersStaffId,
          idxDineOrdersSaleId,
          idxOrderItemsOrderId,
        ]) {
          await m.createIndex(index);
        }
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await _bootstrapBranch();
    },
  );

  /// The branch this device currently operates as (settings `app.branchId`).
  /// Writes stamp it onto sales/purchases/stock so head office can consolidate.
  Future<String?> currentBranchId() => settingsDao.getValue('app.branchId');

  /// Idempotent: guarantees at least one branch exists, backfills any
  /// branch-less legacy rows to it, and pins a current branch for this device.
  Future<void> _bootstrapBranch() async {
    final existing =
        await (select(shops)
              ..where((s) => s.deletedAt.isNull())
              ..limit(1))
            .getSingleOrNull();
    final branchId =
        existing?.id ??
        (await into(
          shops,
        ).insertReturning(ShopsCompanion.insert(name: 'Main Branch'))).id;
    // Backfill rows written before multi-branch existed.
    for (final table in ['stock_movements', 'sales', 'purchases']) {
      await customStatement(
        'UPDATE $table SET branch_id = ? WHERE branch_id IS NULL',
        [branchId],
      );
    }
    final current = await settingsDao.getValue('app.branchId');
    final selected = current == null
        ? null
        : await (select(shops)
                ..where((s) => s.id.equals(current) & s.deletedAt.isNull()))
              .getSingleOrNull();
    if (selected == null) {
      await settingsDao.setValue('app.branchId', branchId);
    }
  }
}
