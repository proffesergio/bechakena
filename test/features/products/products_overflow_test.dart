import 'dart:io';

import 'package:bechakena/app/providers.dart';
import 'package:bechakena/core/db/database.dart';
import 'package:bechakena/core/db/device_store.dart';
import 'package:bechakena/core/money.dart';
import 'package:bechakena/core/seed/demo_catalog.dart';
import 'package:bechakena/features/products/ui/products_screen.dart';
import 'package:bechakena/l10n/gen/app_localizations.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AppDatabase> _db(WidgetTester tester) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await tester.runAsync(() async {
    await seedDemoData(db);
    await db.productsDao.insertProduct(ProductsCompanion.insert(
      name: 'Extra Long Product Name That Might Wrap Across The Row 5kg',
      salePrice: Money(123456),
      businessType: const Value('superShop'),
    ));
  });
  return db;
}

Future<void> _pump(WidgetTester tester, AppDatabase db) async {
  final deviceStore = DeviceStore(
      File('${Directory.systemTemp.path}/bechakena.device.test.json'), {});
  await tester.pumpWidget(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      deviceStoreProvider.overrideWithValue(deviceStore),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ProductsScreen(),
    ),
  ));
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  for (final size in [
    const Size(800, 600),
    const Size(730, 500),
    const Size(400, 700),
  ]) {
    testWidgets('products screen renders without overflow at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final db = await _db(tester);
      await _pump(tester, db);
      expect(find.byType(ListTile), findsWidgets);
      // Open the row actions menu — its ListTile items are another overflow spot.
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Unmount and flush drift's stream-close timer before the db is torn
      // down, otherwise the disposed-widget-tree timer assertion fires.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
