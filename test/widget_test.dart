import 'dart:io';

import 'package:bechakena/app/business_type.dart';
import 'package:bechakena/app/providers.dart';
import 'package:bechakena/core/db/database.dart';
import 'package:bechakena/core/db/device_store.dart';
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

/// Module override that starts already in a chosen module (skips the picker).
class _PickedModule extends BusinessTypeController {
  _PickedModule(this.type);
  final BusinessType type;
  @override
  BusinessType? build() => type;
}

StaffData _staff(StaffRole role) => StaffData(
      id: 's1',
      updatedAt: DateTime.utc(2025),
      deviceId: 'test',
      name: role.name,
      pinHash: 'x',
      role: role,
    );

StaffData _owner() => _staff(StaffRole.owner);

Future<AppDatabase> _pumpApp(WidgetTester tester,
    {StaffData? loggedIn,
    BusinessType? module,
    bool completeFirstRun = false}) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await tester.runAsync(() async {
    await db.customSelect('SELECT 1').get();
    if (completeFirstRun) {
      // Skip the one-time feature tour so the app reaches the login/module gate.
      await db.settingsDao.setValue('app.onboarded', 'true');
    }
  });
  // The app reads the device store (module + theme) before any DB opens, so
  // tests must supply one. An in-memory store (its file is never written here —
  // only theme is read) keeps the app off disk.
  final deviceStore = DeviceStore(
      File('${Directory.systemTemp.path}/bechakena.device.test.json'), {});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        deviceStoreProvider.overrideWithValue(deviceStore),
        databaseProvider.overrideWithValue(db),
        if (loggedIn != null)
          currentStaffProvider.overrideWith(() => _LoggedInSession(loggedIn)),
        if (module != null)
          businessTypeProvider.overrideWith(() => _PickedModule(module)),
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
  testWidgets('after picking a module, first run shows the feature tour',
      (tester) async {
    // A module is chosen but the one-time tour isn't done → the tour runs
    // before login; the shell is not shown yet.
    await _pumpApp(tester, module: BusinessType.superShop);
    expect(find.text('Welcome!'), findsOneWidget);
    expect(find.text('POS'), findsNothing);
    await _teardown(tester);
  });

  testWidgets('after login, the module picker is shown', (tester) async {
    await _pumpApp(tester, loggedIn: _owner(), completeFirstRun: true);
    // No module chosen yet → the picker, not the shell.
    expect(find.text('Which module do you want to open?'), findsOneWidget);
    expect(find.text('POS'), findsNothing);
    await _teardown(tester);
  });

  testWidgets('signing in advances to the shell (not stuck on login)',
      (tester) async {
    // Module picked + onboarded but signed out → the login gate is shown.
    final db = await _pumpApp(tester,
        module: BusinessType.superShop, completeFirstRun: true);
    final staff = await tester.runAsync(() => db.staffDao
        .createStaff(name: 'Owner', pin: '1234', role: StaffRole.owner));
    expect(find.text('POS'), findsNothing);

    // Signing in must swap the gate Navigator over to the shell — the
    // regression was the Navigator keeping the login screen on screen.
    final container = ProviderScope.containerOf(
        tester.element(find.byType(BechaKenaApp)));
    container.read(currentStaffProvider.notifier).login(staff!);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('POS'), findsOneWidget);
    await _teardown(tester);
  });

  testWidgets('supershop module reaches the POS shell', (tester) async {
    await _pumpApp(tester,
        loggedIn: _owner(),
        module: BusinessType.superShop,
        completeFirstRun: true);

    expect(find.text('POS'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('No products yet — add your first product'),
        findsOneWidget);
    await _teardown(tester);
  });

  testWidgets('restaurant module shows the Orders hub and a Tables tab',
      (tester) async {
    await _pumpApp(tester,
        loggedIn: _owner(),
        module: BusinessType.restaurant,
        completeFirstRun: true);

    // Restaurant relabels the nav and inserts a Tables destination.
    expect(find.text('Orders'), findsWidgets);
    expect(find.text('Tables'), findsOneWidget);
    expect(find.text('Menu'), findsOneWidget);
    await _teardown(tester);
  });

  testWidgets('owner sees the full nav rail', (tester) async {
    await _pumpApp(tester,
        loggedIn: _staff(StaffRole.owner),
        module: BusinessType.superShop,
        completeFirstRun: true);
    for (final label in ['POS', 'Products', 'Purchases', 'Inventory',
      'Customers', 'Reports', 'History', 'Settings']) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    await _teardown(tester);
  });

  testWidgets('cashier nav rail is limited to selling', (tester) async {
    await _pumpApp(tester,
        loggedIn: _staff(StaffRole.cashier),
        module: BusinessType.superShop,
        completeFirstRun: true);
    // A cashier can sell, take payments and reach basic settings…
    expect(find.text('POS'), findsWidgets);
    expect(find.text('Customers'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
    // …but the admin/back-office destinations are hidden.
    expect(find.text('Products'), findsNothing);
    expect(find.text('Purchases'), findsNothing);
    expect(find.text('Inventory'), findsNothing);
    expect(find.text('Reports'), findsNothing);
    expect(find.text('History'), findsNothing);
    await _teardown(tester);
  });
}
