import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart' show Locale, ThemeMode;
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

/// App theme mode (system / light / dark), persisted per-device under the
/// `app.themeMode` settings key so the choice survives restarts. Loads
/// asynchronously; until the value is read we default to following the OS.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    final raw =
        await ref.read(databaseProvider).settingsDao.getValue('app.themeMode');
    final mode = _decode(raw);
    if (mode != state) state = mode;
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref
        .read(databaseProvider)
        .settingsDao
        .setValue('app.themeMode', _encode(mode));
  }

  static ThemeMode _decode(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String _encode(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
}

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

/// The branch/outlet this device is currently operating as. Persisted under
/// the `app.branchId` settings key; the DB guarantees it points at a real
/// branch on open. Switching it re-scopes all per-branch stock views.
class CurrentBranchController extends Notifier<String?> {
  @override
  String? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final v =
        await ref.read(databaseProvider).settingsDao.getValue('app.branchId');
    if (v != state) state = v;
  }

  Future<void> set(String branchId) async {
    state = branchId;
    await ref
        .read(databaseProvider)
        .settingsDao
        .setValue('app.branchId', branchId);
  }
}

final currentBranchProvider =
    NotifierProvider<CurrentBranchController, String?>(
        CurrentBranchController.new);

/// All branches (outlets) for the branch picker and head-office views.
final branchesProvider = StreamProvider<List<Shop>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.shops)
        ..where((s) => s.deletedAt.isNull())
        ..orderBy([(s) => OrderingTerm.asc(s.name)]))
      .watch();
});

final productsProvider = StreamProvider<List<Product>>(
    (ref) => ref.watch(databaseProvider).productsDao.watchActive());

final stockProvider = StreamProvider.family<Qty, String>((ref, productId) {
  final branchId = ref.watch(currentBranchProvider);
  return ref
      .watch(databaseProvider)
      .stockDao
      .watchStockFor(productId, branchId: branchId);
});

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

final recentSalesProvider = StreamProvider<List<Sale>>(
    (ref) => ref.watch(databaseProvider).salesDao.watchRecent());

final lowStockProvider = FutureProvider<List<LowStockRow>>((ref) {
  final branchId = ref.watch(currentBranchProvider);
  return ref
      .watch(databaseProvider)
      .stockDao
      .lowStockProducts(branchId: branchId);
});

final expiringSoonProvider = FutureProvider<List<ExpiringBatch>>((ref) {
  final branchId = ref.watch(currentBranchProvider);
  return ref.watch(databaseProvider).stockDao.expiringSoon(
      within: const Duration(days: 14), branchId: branchId);
});
