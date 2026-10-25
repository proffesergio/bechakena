part of 'database.dart';

/// Schema upgrades run atomically; connection setup restores FK enforcement.
extension _SchemaMigration on AppDatabase {
  MigrationStrategy get schemaMigration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      await customStatement('PRAGMA foreign_keys = OFF');
      await transaction(() async {
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
      if (from < 9) {
        // Keep every row while replacing implicit NO ACTION with explicit RESTRICT.
        for (final table in [products, stockMovements, sales, saleItems,
          salePayments, duePayments, returns, returnItems, purchases,
          purchaseItems, smsLog, dineOrders, dineOrderItems]) {
          await m.alterTable(TableMigration(table));
        }
      }
      final violations = await customSelect('PRAGMA foreign_key_check').get();
      if (violations.isNotEmpty) {
        throw StateError('Foreign key violation during database upgrade');
      }
      });
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await _bootstrapBranch();
    },
  );

}
