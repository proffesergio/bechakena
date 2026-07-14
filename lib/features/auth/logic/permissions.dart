import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart' show StaffRole;
import 'session.dart';

/// A single thing a signed-in staff member is allowed to do. Screens, nav
/// destinations and destructive actions are gated on these rather than on the
/// role directly, so the role→permission policy lives in exactly one place
/// ([_matrix]) and is unit-testable without any UI.
enum Capability {
  /// Ring up sales — POS / restaurant orders / tables. Every role can sell.
  sell,

  /// View and manage customers and their baki (due) khata.
  manageCustomers,

  /// Create/edit the product (or menu) catalog.
  manageProducts,

  /// Record supplier purchases (restock).
  managePurchases,

  /// Stock adjustments and the low-stock / expiry dashboards.
  manageInventory,

  /// Reports and the immutable sales history.
  viewReports,

  /// Issue returns / refunds against finalized sales.
  processReturns,

  /// Edit the shop profile (name, logo, footer) and printer setup.
  manageShopProfile,

  /// Add a cashier-level staff member.
  addCashier,

  /// Full staff management — add managers and delete staff.
  manageStaff,

  /// Add and switch the active branch/outlet.
  manageBranches,

  /// Back up and restore this module's database.
  backupRestore,

  /// Wipe all local data for this module (factory reset).
  clearData,

  /// Switch the device to the other business module.
  switchModule,
}

/// Role → capability policy. Owner is intentionally derived as "everything" so
/// adding a new [Capability] never silently locks the owner out of it.
final Map<StaffRole, Set<Capability>> _matrix = {
  StaffRole.owner: Capability.values.toSet(),
  StaffRole.manager: {
    Capability.sell,
    Capability.manageCustomers,
    Capability.manageProducts,
    Capability.managePurchases,
    Capability.manageInventory,
    Capability.viewReports,
    Capability.processReturns,
    Capability.manageShopProfile,
    Capability.addCashier,
  },
  StaffRole.cashier: {
    Capability.sell,
    Capability.manageCustomers,
  },
};

/// Whether [role] is granted [cap]. A null role (locked / signed out) can do
/// nothing.
bool can(StaffRole? role, Capability cap) =>
    role != null && (_matrix[role]?.contains(cap) ?? false);

/// Every capability granted to the currently signed-in staff member (empty when
/// locked). Watch this to gate UI reactively.
final capabilitiesProvider = Provider<Set<Capability>>((ref) {
  final role = ref.watch(currentStaffProvider)?.role;
  return role == null ? const {} : (_matrix[role] ?? const {});
});

/// Convenience: does the current staff member have [cap]?
final canProvider = Provider.family<bool, Capability>(
    (ref, cap) => ref.watch(capabilitiesProvider).contains(cap));
