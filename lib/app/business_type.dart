import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// The module this device runs. Chosen once from the module picker (before
/// login) and **persisted device-level**, so later launches skip the picker and
/// go straight to that module. Each module has its own database, staff and
/// data. Switching modules ([clear]) returns to the picker. Online-sales is
/// intentionally NOT a module — it's a planned optional toggle for the future.
enum BusinessType { superShop, restaurant }

BusinessType? businessTypeFromString(String? v) => switch (v) {
      'superShop' => BusinessType.superShop,
      'restaurant' => BusinessType.restaurant,
      _ => null,
    };

/// The device's persisted module. Loaded from the device store at startup; null
/// only before the very first pick (or after "Switch module"). Because
/// [databaseProvider] keys off this, setting it selects that module's database.
class BusinessTypeController extends Notifier<BusinessType?> {
  @override
  BusinessType? build() =>
      businessTypeFromString(ref.read(deviceStoreProvider).get('module'));

  /// Selects a module. State updates synchronously first (so the DB provider
  /// switches to that module's file immediately), then the choice is persisted.
  Future<void> set(BusinessType type) async {
    state = type;
    await ref.read(deviceStoreProvider).set('module', type.name);
  }

  /// Clears the module ("Switch module") → the picker shows again.
  Future<void> clear() async {
    state = null;
    await ref.read(deviceStoreProvider).set('module', null);
  }
}

final businessTypeProvider =
    NotifierProvider<BusinessTypeController, BusinessType?>(
        BusinessTypeController.new);

/// Convenience: true when running in restaurant mode.
final isRestaurantProvider = Provider<bool>(
    (ref) => ref.watch(businessTypeProvider) == BusinessType.restaurant);

/// The catalog tag ('superShop' / 'restaurant') for the current module, used
/// when creating/scoping products and categories. Defaults to supershop.
final catalogScopeProvider = Provider<String>(
    (ref) => (ref.watch(businessTypeProvider) ?? BusinessType.superShop).name);

/// Whether the one-time feature tour has been completed (settings
/// `app.onboarded`). Shown once, before login.
final onboardedProvider = FutureProvider<bool>((ref) async {
  final v =
      await ref.watch(databaseProvider).settingsDao.getValue('app.onboarded');
  return v == 'true';
});

/// Marks the feature tour complete and re-evaluates the gate.
Future<void> markOnboarded(WidgetRef ref) async {
  await ref
      .read(databaseProvider)
      .settingsDao
      .setValue('app.onboarded', 'true');
  ref.invalidate(onboardedProvider);
}
