// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_dao.dart';

// ignore_for_file: type=lint
mixin _$StockDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTable get categories => attachedDatabase.categories;
  $ProductsTable get products => attachedDatabase.products;
  $StockMovementsTable get stockMovements => attachedDatabase.stockMovements;
  StockDaoManager get managers => StockDaoManager(this);
}

class StockDaoManager {
  final _$StockDaoMixin _db;
  StockDaoManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$StockMovementsTableTableManager get stockMovements =>
      $$StockMovementsTableTableManager(
        _db.attachedDatabase,
        _db.stockMovements,
      );
}
