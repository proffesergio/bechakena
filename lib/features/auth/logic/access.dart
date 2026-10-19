import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart' show Customer, StaffRole;
import 'session.dart';
import 'permissions.dart';

/// Read scope for branch-attributed data (sales history, purchases, customers).
///
/// Owners run the head-office view and may read every branch; every other role
/// is confined to the branch this device currently operates as. Detail views
/// re-check the scope against the record's own branch before rendering, so a
/// record id alone can never expose another counter's data.
final readScopeBranchProvider = Provider<String?>((ref) {
  final role = ref.watch(currentStaffProvider)?.role;
  if (role == StaffRole.owner) return null;
  // Only an owner gets the unrestricted null scope. Empty is a deny-all
  // sentinel while signed out or awaiting branch initialization.
  if (role == null) return '';
  return ref.watch(currentBranchProvider) ?? '';
});

/// Whether a record stamped with [recordBranchId] is readable under
/// [scopeBranchId]. A null scope means "every branch" (owner). A null record
/// branch cannot be attributed safely, so only an owner can read it.
bool canViewBranch(String? scopeBranchId, String? recordBranchId) =>
    scopeBranchId == null ||
    (scopeBranchId.isNotEmpty && scopeBranchId == recordBranchId);

/// Customers visible under the current read scope: owners see all; staff see
/// customers with no branch-attributable sales yet plus customers who have
/// sold at their branch. Customers whose sales all belong to another outlet
/// are hidden from the list and every dialog that starts from it.
final scopedCustomersProvider = StreamProvider<List<Customer>>((ref) {
  final scope = ref.watch(readScopeBranchProvider);
  if (scope == '') return Stream.value(const []);
  return ref.watch(databaseProvider).customersDao.watchAll(branchId: scope);
});

/// Recheck dialogs against the current session and live customer scope, even
/// when a dialog retained a customer object from an earlier session.
final canManageCustomerProvider = Provider.family<bool, String>((ref, id) {
  if (!ref.watch(canProvider(Capability.manageCustomers))) return false;
  final customers = ref.watch(scopedCustomersProvider);
  return !customers.isLoading &&
      !customers.hasError &&
      (customers.value?.any((customer) => customer.id == id) ?? false);
});
