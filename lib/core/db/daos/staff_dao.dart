import 'package:drift/drift.dart';

import '../../auth/pin.dart' as pin_util;
import '../database.dart';

part 'staff_dao.g.dart';

@DriftAccessor(tables: [Staff])
class StaffDao extends DatabaseAccessor<AppDatabase> with _$StaffDaoMixin {
  StaffDao(super.db);

  Future<bool> hasAnyStaff() async {
    final row = await (select(staff)
          ..where((s) => s.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  Future<StaffData> createStaff({
    required String name,
    required String pin,
    required StaffRole role,
  }) =>
      into(staff).insertReturning(StaffCompanion.insert(
        name: name,
        pinHash: pin_util.hashPin(pin),
        role: role,
      ));

  /// Returns the staff row if [pin] matches its hash, else null.
  Future<StaffData?> verifyPin(String staffId, String pin) async {
    final row = await (select(staff)
          ..where((s) => s.id.equals(staffId) & s.deletedAt.isNull()))
        .getSingleOrNull();
    if (row == null) return null;
    return pin_util.verifyPin(pin, row.pinHash) ? row : null;
  }

  Stream<List<StaffData>> watchStaff() => (select(staff)
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
