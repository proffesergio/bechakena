import 'package:bechakena/app/providers.dart';
import 'package:bechakena/core/db/database.dart';
import 'package:bechakena/features/auth/logic/session.dart';
import 'package:bechakena/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Session override that starts already logged-in.
class _LoggedInSession extends SessionController {
  _LoggedInSession(this.staff);
  final StaffData staff;
  @override
  StaffData? build() => staff;
}

StaffData _owner() => StaffData(
      id: 's1',
      updatedAt: DateTime.utc(2025),
      deviceId: 'test',
      name: 'Owner',
      pinHash: 'x',
      role: StaffRole.owner,
    );

Future<AppDatabase> _pumpApp(WidgetTester tester, {StaffData? loggedIn}) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await tester.runAsync(() => db.customSelect('SELECT 1').get());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        if (loggedIn != null)
          currentStaffProvider.overrideWith(() => _LoggedInSession(loggedIn)),
      ],
      child: const BechaKenaApp(),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  return db;
}

Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('first run shows the owner setup gate', (tester) async {
    await _pumpApp(tester);
    expect(find.text('Welcome — create the owner account'), findsOneWidget);
    // The POS shell is NOT shown until logged in.
    expect(find.text('POS'), findsNothing);
    await _teardown(tester);
  });

  testWidgets('logged-in staff reaches the POS shell', (tester) async {
    await _pumpApp(tester, loggedIn: _owner());

    expect(find.text('POS'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('No products yet — add your first product'),
        findsOneWidget);
    await _teardown(tester);
  });
}
