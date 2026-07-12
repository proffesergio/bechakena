import 'package:bechakena/app/providers.dart';
import 'package:bechakena/core/db/database.dart';
import 'package:bechakena/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots to the POS screen with an in-memory db',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    // Open the db with real async before entering fake-async pumping.
    await tester.runAsync(() => db.customSelect('SELECT 1').get());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const BechaKenaApp(),
      ),
    );
    // Bounded pumps: pumpAndSettle would spin on the loading indicator.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Navigation shell is up with the POS tab selected (en in tests).
    expect(find.text('POS'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
    // Empty-state hint of the POS product pane.
    expect(find.text('No products yet — add your first product'),
        findsOneWidget);

    // Unmount and flush drift's stream-close timers so none stay pending.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
