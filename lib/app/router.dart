import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/customers/ui/customers_screen.dart';
import '../features/inventory/ui/inventory_screen.dart';
import '../features/pos/ui/pos_screen.dart';
import '../features/products/ui/products_screen.dart';
import '../features/purchases/ui/purchases_screen.dart';
import '../features/reports/ui/reports_screen.dart';
import '../features/settings/ui/settings_screen.dart';
import '../l10n/gen/app_localizations.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const PosScreen()),
          GoRoute(path: '/products', builder: (_, _) => const ProductsScreen()),
          GoRoute(
              path: '/purchases', builder: (_, _) => const PurchasesScreen()),
          GoRoute(
              path: '/inventory', builder: (_, _) => const InventoryScreen()),
          GoRoute(
              path: '/customers', builder: (_, _) => const CustomersScreen()),
          GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen()),
          GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
        ],
      ),
    ],
  );
});

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _paths = [
    '/',
    '/products',
    '/purchases',
    '/inventory',
    '/customers',
    '/reports',
    '/settings',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final index = _paths.indexOf(location).clamp(0, _paths.length - 1);
    return Scaffold(
      body: Row(
        children: [
          // Height-safe: the rail scrolls if the window is short.
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: NavigationRail(
                    selectedIndex: index,
                    labelType: NavigationRailLabelType.all,
                    onDestinationSelected: (i) => context.go(_paths[i]),
                    destinations: [
                      NavigationRailDestination(
                          icon: const Icon(Icons.point_of_sale),
                          label: Text(l10n.navPos)),
                      NavigationRailDestination(
                          icon: const Icon(Icons.inventory_2),
                          label: Text(l10n.navProducts)),
                      NavigationRailDestination(
                          icon: const Icon(Icons.local_shipping),
                          label: Text(l10n.navPurchases)),
                      NavigationRailDestination(
                          icon: const Icon(Icons.warehouse),
                          label: Text(l10n.navInventory)),
                      NavigationRailDestination(
                          icon: const Icon(Icons.people),
                          label: Text(l10n.navCustomers)),
                      NavigationRailDestination(
                          icon: const Icon(Icons.bar_chart),
                          label: Text(l10n.navReports)),
                      NavigationRailDestination(
                          icon: const Icon(Icons.settings),
                          label: Text(l10n.navSettings)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
