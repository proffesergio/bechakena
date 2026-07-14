import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/customers/ui/customers_screen.dart';
import '../features/history/ui/history_screen.dart';
import '../features/inventory/ui/inventory_screen.dart';
import '../features/pos/ui/pos_screen.dart';
import '../features/products/ui/products_screen.dart';
import '../features/purchases/ui/purchases_screen.dart';
import '../features/reports/ui/reports_screen.dart';
import '../features/settings/ui/settings_screen.dart';
import '../features/auth/logic/permissions.dart';
import '../features/tables/ui/orders_screen.dart';
import '../features/tables/ui/tables_screen.dart';
import '../l10n/gen/app_localizations.dart';
import 'business_type.dart';

/// Capability required to open a route. Absent → the route is open to any
/// signed-in staff member. Used both to filter the nav rail and to guard deep
/// links (a cashier who types `/reports` is bounced back to `/`).
const _routeCapability = <String, Capability>{
  '/products': Capability.manageProducts,
  '/purchases': Capability.managePurchases,
  '/inventory': Capability.manageInventory,
  '/reports': Capability.viewReports,
  '/history': Capability.viewReports,
};

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    redirect: (context, state) {
      final cap = _routeCapability[state.uri.path];
      if (cap == null) return null; // open route
      return ref.read(capabilitiesProvider).contains(cap) ? null : '/';
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const _HomeScreen()),
          GoRoute(path: '/tables', builder: (_, _) => const TablesScreen()),
          GoRoute(path: '/products', builder: (_, _) => const ProductsScreen()),
          GoRoute(
              path: '/purchases', builder: (_, _) => const PurchasesScreen()),
          GoRoute(
              path: '/inventory', builder: (_, _) => const InventoryScreen()),
          GoRoute(
              path: '/customers', builder: (_, _) => const CustomersScreen()),
          GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen()),
          GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
          GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
        ],
      ),
    ],
  );
});

/// The `/` landing: the retail POS in supershop mode, the restaurant Orders hub
/// (open tabs + new takeaway/delivery) in restaurant mode.
class _HomeScreen extends ConsumerWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
          .watch(isRestaurantProvider)
      ? const OrdersScreen()
      : const PosScreen();
}

/// One navigation-rail destination. [cap] is the capability needed to see it
/// (null = shown to everyone).
class _Nav {
  const _Nav(this.path, this.icon, this.label, {this.cap});
  final String path;
  final IconData icon;
  final String label;
  final Capability? cap;
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final restaurant = ref.watch(isRestaurantProvider);
    final caps = ref.watch(capabilitiesProvider);

    // Restaurant mode inserts a Tables destination and relabels a couple of
    // sections; supershop mode keeps the retail wording. Destinations the
    // current staff role can't use are filtered out (a cashier sees only the
    // sell / customers / settings basics).
    final dests = <_Nav>[
      _Nav('/', Icons.point_of_sale,
          restaurant ? l10n.navOrders : l10n.navPos),
      if (restaurant) _Nav('/tables', Icons.table_restaurant, l10n.navTables),
      _Nav('/products', Icons.inventory_2,
          restaurant ? l10n.navMenu : l10n.navProducts,
          cap: Capability.manageProducts),
      _Nav('/purchases', Icons.local_shipping, l10n.navPurchases,
          cap: Capability.managePurchases),
      _Nav('/inventory', Icons.warehouse, l10n.navInventory,
          cap: Capability.manageInventory),
      _Nav('/customers', Icons.people, l10n.navCustomers),
      _Nav('/reports', Icons.bar_chart, l10n.navReports,
          cap: Capability.viewReports),
      _Nav('/history', Icons.history, l10n.navHistory,
          cap: Capability.viewReports),
      _Nav('/settings', Icons.settings, l10n.navSettings),
    ].where((d) => d.cap == null || caps.contains(d.cap)).toList();
    final index =
        dests.indexWhere((d) => d.path == location).clamp(0, dests.length - 1);

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
                    onDestinationSelected: (i) => context.go(dests[i].path),
                    destinations: [
                      for (final d in dests)
                        NavigationRailDestination(
                            icon: Icon(d.icon), label: Text(d.label)),
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
