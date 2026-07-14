import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/brand.dart';
import 'app/business_type.dart';
import 'app/providers.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'app/widgets/app_loader.dart';
import 'core/db/device_store.dart';
import 'core/db/open.dart';
import 'features/auth/logic/session.dart';
import 'features/auth/ui/login_screen.dart';
import 'features/onboarding/ui/module_picker_screen.dart';
import 'features/onboarding/ui/onboarding_screen.dart';
import 'l10n/gen/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Retire any pre-split single database so both modules start clean, then load
  // the device-level store (module choice + theme) before the app builds.
  await archiveLegacyDatabase();
  final deviceStore = await DeviceStore.load();
  runApp(ProviderScope(
    overrides: [deviceStoreProvider.overrideWithValue(deviceStore)],
    child: const BechaKenaApp(),
  ));
}

class BechaKenaApp extends ConsumerWidget {
  const BechaKenaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (_) => Brand.name,
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: ref.watch(themeModeProvider),
      locale: ref.watch(localeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
      // First-run gate → business type → feature tour → staff login → app.
      builder: (context, child) => _AppGate(child: child!),
    );
  }
}

/// Runs the first-launch sequence, then the login gate, then the app. Each gate
/// screen gets its own Navigator so its fields/dialogs have an Overlay ancestor.
class _AppGate extends ConsumerWidget {
  const _AppGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Module picker comes first — before login — because the chosen module
    // decides which database (and therefore which staff) we authenticate
    // against. While no module is selected we never touch a module DB.
    final module = ref.watch(businessTypeProvider);
    if (module == null) return _gate(const ModulePickerScreen());

    // A module is set → its DB is available. Order within a module:
    // one-time feature tour → staff login/owner-setup → app.
    final onboarded = ref.watch(onboardedProvider);
    return onboarded.when(
      loading: () => const SplashScreen(),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (done) {
        if (!done) return _gate(const OnboardingScreen());
        if (ref.watch(currentStaffProvider) == null) {
          return _gate(const LoginScreen());
        }
        return child;
      },
    );
  }

  /// Wraps a gate screen in its own keyed Navigator. The key matters: a bare
  /// Navigator only runs onGenerateRoute for its *initial* route, so without a
  /// per-gate key Flutter would reuse the same Navigator across gate changes and
  /// keep showing the old screen (e.g. stay on login after signing in). A
  /// changing key forces a fresh Navigator — and each gate gets its own Overlay
  /// for fields/dialogs.
  Widget _gate(Widget gate) => Navigator(
        key: ValueKey(gate.runtimeType),
        onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => gate),
      );
}
