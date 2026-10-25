import 'package:bechakena/app/providers.dart';
import 'package:bechakena/app/widgets/manual_item_dialog.dart';
import 'package:bechakena/core/money.dart';
import 'package:bechakena/core/qty.dart';
import 'package:bechakena/features/auth/logic/permissions.dart';
import 'package:bechakena/features/settings/data/business_settings.dart';
import 'package:bechakena/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shared item form rejects invalid amounts and preserves exact quantities', (tester) async {
    var saved = false;
    await tester.pumpWidget(ProviderScope(overrides: [
      capabilitiesProvider.overrideWithValue({Capability.sell}),
      businessSettingsProvider.overrideWith((ref) => Stream.value(const BusinessSettings())),
    ], child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Builder(builder: (context) => TextButton(
        onPressed: () => showDialog<void>(context: context, builder: (_) => ManualItemDialog(onSave: (name, price, qty) {
        expect(name, 'Tea');
        expect(price, const Money(12550));
        expect(qty, const Qty(250));
        saved = true;
      })), child: const Text('Open')))),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), ' Tea ');
    await tester.enterText(fields.at(1), '-1');
    await tester.enterText(fields.at(2), '0');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();
    expect(saved, isFalse);
    await tester.enterText(fields.at(1), '125.50');
    await tester.enterText(fields.at(2), '0.250');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(saved, isTrue);
  });
}
