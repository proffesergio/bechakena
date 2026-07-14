// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orders_dao.dart';

// ignore_for_file: type=lint
mixin _$OrdersDaoMixin on DatabaseAccessor<AppDatabase> {
  $DiningTablesTable get diningTables => attachedDatabase.diningTables;
  $ShopsTable get shops => attachedDatabase.shops;
  $StaffTable get staff => attachedDatabase.staff;
  $CustomersTable get customers => attachedDatabase.customers;
  $SalesTable get sales => attachedDatabase.sales;
  $DineOrdersTable get dineOrders => attachedDatabase.dineOrders;
  $CategoriesTable get categories => attachedDatabase.categories;
  $ProductsTable get products => attachedDatabase.products;
  $DineOrderItemsTable get dineOrderItems => attachedDatabase.dineOrderItems;
  OrdersDaoManager get managers => OrdersDaoManager(this);
}

class OrdersDaoManager {
  final _$OrdersDaoMixin _db;
  OrdersDaoManager(this._db);
  $$DiningTablesTableTableManager get diningTables =>
      $$DiningTablesTableTableManager(_db.attachedDatabase, _db.diningTables);
  $$ShopsTableTableManager get shops =>
      $$ShopsTableTableManager(_db.attachedDatabase, _db.shops);
  $$StaffTableTableManager get staff =>
      $$StaffTableTableManager(_db.attachedDatabase, _db.staff);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db.attachedDatabase, _db.sales);
  $$DineOrdersTableTableManager get dineOrders =>
      $$DineOrdersTableTableManager(_db.attachedDatabase, _db.dineOrders);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$DineOrderItemsTableTableManager get dineOrderItems =>
      $$DineOrderItemsTableTableManager(
        _db.attachedDatabase,
        _db.dineOrderItems,
      );
}
