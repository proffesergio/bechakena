import 'package:bechakena/core/db/database.dart';
import 'package:bechakena/core/money.dart';
import 'package:bechakena/core/seed/demo_catalog.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  test('seeds a full catalog into an empty database', () async {
    expect(await seedDemoData(db), isTrue);
    final products = await db.productsDao.watchActive().first;
    expect(products.length, greaterThan(40));
    // Every product localized and drawable.
    for (final p in products) {
      expect(p.nameBn, isNotEmpty);
      expect(p.imagePath, startsWith('emoji:'));
      expect(p.categoryId, isNotNull);
    }
    // Stock arrived via movements, derived as always.
    final any = products.first;
    expect((await db.stockDao.stockFor(any.id)).milli, greaterThan(0));
  });

  test('refuses to seed when products already exist', () async {
    await db.productsDao.insertProduct(ProductsCompanion.insert(
        name: 'Real product', salePrice: const Money(1000)));
    expect(await seedDemoData(db), isFalse);
    final products = await db.productsDao.watchActive().first;
    expect(products.length, 1);
  });
}
