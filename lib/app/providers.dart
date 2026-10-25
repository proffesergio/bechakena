import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart' show Locale, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'business_type.dart';

import '../core/db/database.dart';
import '../core/db/device_store.dart';
import '../core/db/open.dart';
import '../core/money.dart';
import '../core/qty.dart';
import '../core/currency.dart';
import '../features/settings/data/business_settings.dart';

final businessSettingsStoreProvider = Provider<BusinessSettingsStore>(
  (ref) => BusinessSettingsStore(ref.watch(databaseProvider)),
);

final businessSettingsProvider = StreamProvider<BusinessSettings>(
  (ref) => ref.watch(businessSettingsStoreProvider).watch(),
);

/// Fail closed while loading: rendering or parsing in a guessed currency can
/// misrepresent persisted amounts. UI hosts show their usual loading/error UI.
final shopCurrencyProvider = Provider<ShopCurrency>(
  (ref) => ref.watch(businessSettingsProvider).requireValue.currency,
);

/// Device-level settings store (module choice, theme). Loaded once before the
/// app starts and injected via an override in `main()`.
final deviceStoreProvider = Provider<DeviceStore>(
  (ref) => throw StateError('deviceStoreProvider must be overridden'),
);

/// The active module's database. Each module gets its own SQLite file, so
/// switching modules disposes one DB and opens the other — data never crosses
/// between modules. Only read once a module is selected (the gate enforces it).
final databaseProvider = Provider<AppDatabase>((ref) {
  final module = ref.watch(businessTypeProvider);
  if (module == null) {
    throw StateError('No module selected — pick a module before using the DB');
  }
  final db = AppDatabase(openAppDatabase(module.name));
  ref.onDispose(db.close);
  return db;
});

/// null = follow the system locale. Shared device-level language preference.
class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    final code = ref.read(deviceStoreProvider).get('locale');
    return code == 'bn' || code == 'en' ? Locale(code!) : null;
  }

  Future<void> set(Locale? locale) async {
    if (locale != null && !{'bn', 'en'}.contains(locale.languageCode)) {
      throw ArgumentError.value(locale, 'locale');
    }
    await ref
        .read(deviceStoreProvider)
        .set('locale', locale?.languageCode ?? '');
    state = locale;
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

/// App theme mode (system / light / dark), persisted **device-level** (in the
/// device store, not a module DB) under `themeMode` so the app can paint before
/// any module database is open and the choice is shared across modules.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => _decode(ref.read(deviceStoreProvider).get('themeMode'));

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(deviceStoreProvider).set('themeMode', _encode(mode));
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

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

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
    final v = await ref
        .read(databaseProvider)
        .settingsDao
        .getValue('app.branchId');
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
      CurrentBranchController.new,
    );

/// All branches (outlets) for the branch picker and head-office views.
final branchesProvider = StreamProvider<List<Shop>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.shops)
        ..where((s) => s.deletedAt.isNull())
        ..orderBy([(s) => OrderingTerm.asc(s.name)]))
      .watch();
});

final productsProvider = StreamProvider<List<Product>>((ref) {
  final scope = ref.watch(catalogScopeProvider);
  return ref
      .watch(databaseProvider)
      .productsDao
      .watchActive(businessType: scope);
});

/// Dining tables (restaurant mode only; empty otherwise).
final diningTablesProvider = StreamProvider<List<DiningTable>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.diningTables)
        ..where((t) => t.deletedAt.isNull())
        ..where((t) => t.isActive.equals(true))
        ..orderBy([
          (t) => OrderingTerm.asc(t.sortOrder),
          (t) => OrderingTerm.asc(t.name),
        ]))
      .watch();
});

/// All open restaurant orders (running tabs) across dine-in, takeaway and
/// delivery. Drives the Orders hub and each table's free/occupied status.
final openOrdersProvider = StreamProvider<List<DineOrder>>(
  (ref) {
    final branchId = ref.watch(currentBranchProvider);
    if (branchId == null || branchId.isEmpty) return Stream.value(const <DineOrder>[]);
    return ref.watch(databaseProvider).ordersDao.watchOpenOrders(branchId: branchId);
  },
);

/// Line items of one running order, live.
final orderItemsProvider = StreamProvider.family<List<DineOrderItem>, String>(
  (ref, orderId) {
    final branchId = ref.watch(currentBranchProvider);
    if (branchId == null || branchId.isEmpty) return Stream.value(const <DineOrderItem>[]);
    return ref.watch(databaseProvider).ordersDao.watchItems(orderId, branchId: branchId);
  },
);

final stockProvider = StreamProvider.family<Qty, String>((ref, productId) {
  final branchId = ref.watch(currentBranchProvider);
  if (branchId == null || branchId.isEmpty) { return Stream.value(Qty.zero); }
  return ref
      .watch(databaseProvider)
      .stockDao
      .watchStockFor(productId, branchId: branchId);
});

/// Categories by id, for product-card colors and filter chips.
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  final scope = ref.watch(catalogScopeProvider);
  return (db.select(db.categories)
        ..where((c) => c.deletedAt.isNull())
        ..where((c) => c.businessType.equals(scope))
        ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
      .watch();
});

/// The branch/role-scoped customer list lives in
/// `features/auth/logic/access.dart` (`scopedCustomersProvider`) so read-path
/// ownership checks sit next to the access policy.
final customerDueProvider = FutureProvider.family<Money, String>(
  (ref, customerId) =>
      ref.watch(databaseProvider).customersDao.dueFor(customerId),
);

final lowStockProvider = FutureProvider<List<LowStockRow>>((ref) {
  final branchId = ref.watch(currentBranchProvider);
  if (branchId == null || branchId.isEmpty) { return []; }
  return ref
      .watch(databaseProvider)
      .stockDao
      .lowStockProducts(branchId: branchId);
});

final expiringSoonProvider = FutureProvider<List<ExpiringBatch>>((ref) {
  final branchId = ref.watch(currentBranchProvider);
  if (branchId == null || branchId.isEmpty) { return []; }
  return ref
      .watch(databaseProvider)
      .stockDao
      .expiringSoon(within: const Duration(days: 14), branchId: branchId);
});
