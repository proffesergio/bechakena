import '../../../core/currency.dart';
import '../../../core/db/database.dart';

enum BusinessSettingsError { forbidden, currencyLocked, invalidTaxDetails }

class BusinessSettingsException implements Exception {
  const BusinessSettingsException(this.reason);
  final BusinessSettingsError reason;
}

class BusinessSettings {
  const BusinessSettings({
    this.currency = ShopCurrency.bdt,
    this.taxLabel = 'VAT',
    this.taxId = '',
  });
  final ShopCurrency currency;
  final String taxLabel;
  final String taxId;
}

/// Module-wide accounting configuration: every branch shares one currency.
/// Settings are local and included in the module's database backup.
class BusinessSettingsStore {
  BusinessSettingsStore(this.db);
  final AppDatabase db;

  Future<BusinessSettings> load() async => BusinessSettings(
    currency: ShopCurrency.decode(
      await db.settingsDao.getValue('business.currency'),
    ),
    taxLabel: await db.settingsDao.getValue('business.taxLabel') ?? 'VAT',
    taxId: await db.settingsDao.getValue('business.taxId') ?? '',
  );

  Stream<BusinessSettings> watch() =>
      db.select(db.settings).watch().asyncMap((_) => load());

  /// Include soft-deleted rows: deleting a product must never unlock amounts
  /// already recorded under the old currency. No schema migration is needed.
  Future<bool> currencyLocked() async {
    final row = await db.customSelect('''SELECT
      EXISTS(SELECT 1 FROM products) OR EXISTS(SELECT 1 FROM sales) OR
      EXISTS(SELECT 1 FROM purchases) OR EXISTS(SELECT 1 FROM due_payments) OR
      EXISTS(SELECT 1 FROM sale_payments) OR EXISTS(SELECT 1 FROM returns) OR
      EXISTS(SELECT 1 FROM dine_order_items) AS locked''').getSingle();
    return row.read<int>('locked') != 0;
  }

  /// Recheck the live session at the mutation boundary, including after awaits.
  /// Callers must supply a live capability lookup, never a cached role.
  Future<void> save(
    BusinessSettings value, {
    required bool Function() canManage,
  }) => db.transaction(() async {
    void authorize() {
      if (!canManage())
        throw const BusinessSettingsException(BusinessSettingsError.forbidden);
    }

    authorize();
    final taxLabel = value.taxLabel.trim();
    final taxId = value.taxId.trim();
    final invalid = RegExp(r'[\x00-\x1f\x7f]');
    if (taxLabel.isEmpty ||
        taxLabel.length > 32 ||
        taxId.length > 80 ||
        invalid.hasMatch(taxLabel) ||
        invalid.hasMatch(taxId)) {
      throw const BusinessSettingsException(
        BusinessSettingsError.invalidTaxDetails,
      );
    }
    final previous = await load();
    if (previous.currency != value.currency && await currencyLocked()) {
      throw const BusinessSettingsException(
        BusinessSettingsError.currencyLocked,
      );
    }
    authorize();
    await db.settingsDao.setValue('business.currency', value.currency.code);
    await db.settingsDao.setValue('business.taxLabel', taxLabel);
    await db.settingsDao.setValue('business.taxId', taxId);
    authorize();
  });
}
