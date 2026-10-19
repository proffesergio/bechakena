import 'package:bechakena/core/db/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  group('StaffDao', () {
    test('persisted lockout blocks valid PIN then upgrades a legacy hash after expiry', () async {
      final created = await db.into(db.staff).insertReturning(StaffCompanion.insert(
        name: 'Legacy', role: StaffRole.cashier,
        pinHash: r'pbkdf2sha256$1$c2FsdHNhbHQ=$cnodo4POYzHowTVUDQWUh+jBDYuoM7zPsnOdQf74gN8=',
      ));
      await db.settingsDao.setValue('auth.failures.${created.id}', '4');
      expect(await db.staffDao.verifyPin(created.id, '0000'), isNull);
      expect(await StaffDao(db).verifyPin(created.id, '1234'), isNull);
      await db.settingsDao.setValue('auth.lock.${created.id}', '0');
      final upgraded = await db.staffDao.verifyPin(created.id, '1234');
      expect(upgraded, isNotNull);
      expect(upgraded!.pinHash, startsWith(r'pbkdf2sha256$600000$'));
      expect(await db.settingsDao.getValue('auth.failures.${created.id}'), '0');
    });
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
