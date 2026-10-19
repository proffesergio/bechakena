import 'package:drift/drift.dart';

import '../../auth/pin.dart' as pin_util;
import '../../auth/pin_async.dart';
import '../database.dart';

part 'staff_dao.g.dart';

@DriftAccessor(tables: [Staff])
class StaffDao extends DatabaseAccessor<AppDatabase> with _$StaffDaoMixin {
  StaffDao(super.db);
  final _verifying = <String>{};

  Future<bool> hasAnyStaff() async {
    final row =
        await (select(staff)
              ..where((s) => s.deletedAt.isNull())
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  Future<StaffData> createStaff({
    required String name,
    required String pin,
    required StaffRole role,
  }) async => into(staff).insertReturning(
    StaffCompanion.insert(
      name: name,
      pinHash: await hashPinAsync(pin),
      role: role,
    ),
  );

  /// Returns the staff row if [pin] matches its hash, else null.
  Future<StaffData?> verifyPin(String staffId, String pin) async {
    if (!_verifying.add(staffId)) return null;
    try {
      final settings = attachedDatabase.settingsDao;
      final lockKey = 'auth.lock.$staffId';
      final failedKey = 'auth.failures.$staffId';
      final until = int.tryParse(await settings.getValue(lockKey) ?? '') ?? 0;
      if (DateTime.now().millisecondsSinceEpoch < until) return null;
      final row =
          await (select(staff)
                ..where((s) => s.id.equals(staffId) & s.deletedAt.isNull()))
              .getSingleOrNull();
      if (row == null) return null;
      final verified = await verifyPinAsync(pin, row.pinHash);
      if (!verified) {
        final failed =
            (int.tryParse(await settings.getValue(failedKey) ?? '') ?? 0) + 1;
        await settings.setValue(failedKey, '$failed');
        if (failed >= 5) {
          await settings.setValue(
            lockKey,
            '${DateTime.now().add(const Duration(seconds: 30)).millisecondsSinceEpoch}',
          );
          await settings.setValue(failedKey, '0');
        }
        return null;
      }
      await settings.setValue(failedKey, '0');
      await settings.setValue(lockKey, '0');
      if (pin_util.pinHashNeedsUpgrade(row.pinHash)) {
        final strengthened = await hashPinAsync(pin);
        await (update(staff)..where((s) => s.id.equals(staffId))).write(
          StaffCompanion(
            pinHash: Value(strengthened),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
        return await (select(
          staff,
        )..where((s) => s.id.equals(staffId))).getSingle();
      }
      return row;
    } finally {
      _verifying.remove(staffId);
    }
  }

  Stream<List<StaffData>> watchStaff() =>
      (select(staff)
            ..where((s) => s.deletedAt.isNull())
            ..orderBy([(s) => OrderingTerm.asc(s.name)]))
          .watch();

  Future<void> softDelete(String id) =>
      (update(staff)..where((s) => s.id.equals(id))).write(
        StaffCompanion(
          deletedAt: Value(DateTime.now().toUtc()),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
}
