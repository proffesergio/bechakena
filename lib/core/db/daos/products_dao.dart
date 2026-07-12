import 'package:drift/drift.dart';

import '../database.dart';

part 'products_dao.g.dart';

@DriftAccessor(tables: [Products])
class ProductsDao extends DatabaseAccessor<AppDatabase> with _$ProductsDaoMixin {
  ProductsDao(super.db);

  Future<Product> insertProduct(ProductsCompanion entry) =>
      into(products).insertReturning(entry);

  Future<void> updateProduct(Product product) => update(products).replace(
      product.copyWith(updatedAt: DateTime.now().toUtc()));

  Future<Product?> byId(String id) =>
      (select(products)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<Product?> byBarcode(String barcode) => (select(products)
        ..where((p) =>
            p.barcode.equals(barcode) &
            p.deletedAt.isNull() &
            p.isActive.equals(true)))
      .getSingleOrNull();

  Stream<List<Product>> watchActive() => (select(products)
        ..where((p) => p.deletedAt.isNull() & p.isActive.equals(true))
        ..orderBy([(p) => OrderingTerm.asc(p.name)]))
      .watch();

  /// Soft delete per the sync contract — rows are never physically removed.
  Future<void> softDelete(String id) =>
      (update(products)..where((p) => p.id.equals(id))).write(
        ProductsCompanion(
          deletedAt: Value(DateTime.now().toUtc()),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
}
