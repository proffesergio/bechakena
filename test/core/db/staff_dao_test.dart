import 'package:bechakena/core/db/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  group('StaffDao', () {
    test('empty shop has no staff', () async {
      expect(await db.staffDao.hasAnyStaff(), isFalse);
    });

    test('create hashes the PIN (never stores it plainly)', () async {
      final staff = await db.staffDao
          .createStaff(name: 'Owner', pin: '4321', role: StaffRole.owner);
      expect(staff.pinHash, isNot(contains('4321')));
      expect(await db.staffDao.hasAnyStaff(), isTrue);
    });

    test('verifyPin returns the staff for a correct PIN', () async {
      final created = await db.staffDao
          .createStaff(name: 'Cashier', pin: '1111', role: StaffRole.cashier);
      final ok = await db.staffDao.verifyPin(created.id, '1111');
      expect(ok, isNotNull);
      expect(ok!.name, 'Cashier');
    });

    test('verifyPin returns null for a wrong PIN', () async {
      final created = await db.staffDao
          .createStaff(name: 'Cashier', pin: '1111', role: StaffRole.cashier);
      expect(await db.staffDao.verifyPin(created.id, '9999'), isNull);
    });

    test('watchStaff lists active staff, excludes soft-deleted', () async {
      final a = await db.staffDao
          .createStaff(name: 'A', pin: '1234', role: StaffRole.owner);
      await db.staffDao
          .createStaff(name: 'B', pin: '2345', role: StaffRole.cashier);
      expect((await db.staffDao.watchStaff().first).length, 2);
      await db.staffDao.softDelete(a.id);
      expect((await db.staffDao.watchStaff().first).length, 1);
    });
  });
}
