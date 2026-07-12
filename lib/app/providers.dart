import 'dart:ui';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/db/database.dart';
import '../core/db/open.dart';
import '../core/money.dart';
import '../core/qty.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(openAppDatabase());
  ref.onDispose(db.close);
  return db;
});

/// null = follow the system locale. Persisted per-shop in settings (v1.1).
class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() => null;

  void set(Locale? locale) => state = locale;
}

final localeProvider =
    NotifierProvider<LocaleController, Locale?>(LocaleController.new);

final productsProvider = StreamProvider<List<Product>>(
    (ref) => ref.watch(databaseProvider).productsDao.watchActive());

final stockProvider = StreamProvider.family<Qty, String>(
    (ref, productId) =>
        ref.watch(databaseProvider).stockDao.watchStockFor(productId));

/// Categories by id, for product-card colors and filter chips.
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.categories)
        ..where((c) => c.deletedAt.isNull())
        ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
      .watch();
});

final customersProvider = StreamProvider<List<Customer>>(
    (ref) => ref.watch(databaseProvider).customersDao.watchAll());

final customerDueProvider = FutureProvider.family<Money, String>(
    (ref, customerId) =>
        ref.watch(databaseProvider).customersDao.dueFor(customerId));

final todaySalesProvider = StreamProvider<List<Sale>>((ref) =>
    ref.watch(databaseProvider).salesDao.watchSalesOn(DateTime.now().toUtc()));
