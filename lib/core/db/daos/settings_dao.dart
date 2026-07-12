import 'package:drift/drift.dart';

import '../database.dart';

part 'settings_dao.g.dart';

/// Device-local key/value store (printer config, locale, license blob…).
@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<String?> getValue(String key) async {
    final row = await (select(settings)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setValue(String key, String value) =>
      into(settings).insertOnConflictUpdate(
          SettingsCompanion.insert(key: key, value: value));
}
