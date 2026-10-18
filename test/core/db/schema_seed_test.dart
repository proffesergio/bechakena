import 'dart:io';

import 'package:bechakena/core/db/database.dart';
import 'package:bechakena/core/money.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Guards `database/schema.sql` and `database/seed.sql`: applies both to a
/// fresh SQLite file and then opens that file with the app's own database,
/// proving the shipped scripts create a system the app accepts as current.
void main() {
  late Directory tempDir;
  late String dbPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('bechakena_seed_test');
    dbPath = '${tempDir.path}/bechakena.db';
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  test('schema.sql + seed.sql produce a database the app opens', () async {
    final sqlite = sqlite3.open(dbPath);
    try {
      sqlite.execute(File('database/schema.sql').readAsStringSync());
      sqlite.execute(File('database/seed.sql').readAsStringSync());

      final tables = sqlite
          .select("SELECT name FROM sqlite_master "
              "WHERE type = 'table' AND name NOT LIKE 'sqlite_%'")
          .map((row) => row['name'] as String)
          .toSet();
      expect(tables, hasLength(21));
      expect(sqlite.select('PRAGMA integrity_check').single.values.first, 'ok');
      expect(sqlite.select('PRAGMA user_version').single.values.first, 6);
    } finally {
      sqlite.close();
    }

    // The app opens the script-created file exactly as it would its own, and
    // must not attempt to re-run migrations (user_version is current).
    final db = AppDatabase(NativeDatabase(File(dbPath)));
    try {
      final shops = await db.select(db.shops).get();
      expect(shops.single.name, 'BechaKena Demo Shop');

      final owner = (await db.select(db.staff).get()).single;
      expect(owner.role, StaffRole.owner);
      expect(await db.staffDao.verifyPin(owner.id, '1234'), isNotNull);
      expect(await db.staffDao.verifyPin(owner.id, '9999'), isNull);

      final retail = await (db.select(db.products)
            ..where((p) => p.businessType.equals('superShop')))
          .get();
      final menu = await (db.select(db.products)
            ..where((p) => p.businessType.equals('restaurant')))
          .get();
      expect(retail, isNotEmpty);
      expect(menu, isNotEmpty);

      final rice = retail.firstWhere((p) => p.name == 'Miniket Rice 5kg');
      expect((await db.stockDao.stockFor(rice.id)).isZero, isFalse);

      final sales = await db.select(db.sales).get();
      expect(sales, hasLength(3));

      final karim = (await db.select(db.customers).get())
          .firstWhere((c) => c.name == 'করিম মিয়া');
      expect(await db.customersDao.dueFor(karim.id), const Money(25000));

      final tables = await db.select(db.diningTables).get();
      expect(tables, isNotEmpty);
    } finally {
      await db.close();
    }
  });
}
