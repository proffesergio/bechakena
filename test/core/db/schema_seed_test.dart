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
      expect(sqlite.select('PRAGMA user_version').single.values.first, 8);

      final indexes = sqlite
          .select("SELECT name FROM sqlite_master WHERE type = 'index' "
              "AND name LIKE 'idx_%'")
          .map((row) => row['name'] as String)
          .toSet();
      expect(
          indexes,
          containsAll({
            'idx_stock_movements_product_id',
            'idx_sale_items_product_id',
            'idx_purchase_items_product_id',
            'idx_order_items_product_id',
          }));
      for (final table in tables) {
        final indexedColumns = sqlite.select('PRAGMA index_list("$table")')
            .expand((index) => sqlite.select('PRAGMA index_info("${index['name']}")')
                .where((column) => column['seqno'] == 0)
                .map((column) => column['name']))
            .toSet();
        for (final foreignKey in sqlite.select('PRAGMA foreign_key_list("$table")')) {
          expect(indexedColumns, contains(foreignKey['from']),
              reason: '$table.${foreignKey['from']} needs an index prefix');
        }
      }
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

  test('version 7 databases gain all version 8 indexes without losing rows', () async {
    const previousIndexes = {
      'idx_stock_movements_product_id', 'idx_sale_items_product_id',
      'idx_purchase_items_product_id', 'idx_order_items_product_id',
    };
    final sqlite = sqlite3.open(dbPath);
    try {
      sqlite.execute(File('database/schema.sql').readAsStringSync());
      final indexes = sqlite.select("SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_%'");
      for (final index in indexes) {
        final name = index['name'] as String;
        if (!previousIndexes.contains(name)) sqlite.execute('DROP INDEX "$name"');
      }
      sqlite.execute('PRAGMA user_version = 7');
    } finally {
      sqlite.close();
    }
    final db = AppDatabase(NativeDatabase(File(dbPath)));
    try {
      expect(await db.select(db.shops).get(), hasLength(1));
      final indexes = await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_%'").get();
      expect(indexes, hasLength(25));
      expect((await db.customSelect('PRAGMA user_version').getSingle()).read<int>('user_version'), 8);
    } finally {
      await db.close();
    }
  });
}
