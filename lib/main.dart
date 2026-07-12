import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/brand.dart';
import 'app/providers.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'features/auth/logic/session.dart';
import 'features/auth/ui/login_screen.dart';
import 'l10n/gen/app_localizations.dart';

void main() {
  runApp(const ProviderScope(child: BechaKenaApp()));
}

class BechaKenaApp extends ConsumerWidget {
  const BechaKenaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (_) => Brand.name,
      theme: lightTheme(),
      darkTheme: darkTheme(),
      locale: ref.watch(localeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
      // Gate the whole app behind staff login (offline PIN). The login screen
      // gets its own Navigator so its fields/dialogs have an Overlay ancestor.
      builder: (context, child) {
        final staff = ref.watch(currentStaffProvider);
        if (staff != null) return child!;
        return Navigator(
          onGenerateRoute: (_) =>
              MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        );
      },
    );
  }
}
