import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/rbac.dart';
export '../../../core/auth/rbac.dart';
import 'session.dart';

/// A single thing a signed-in staff member is allowed to do. Screens, nav
/// destinations and destructive actions are gated on these rather than on the
/// role directly, so the role→permission policy lives in exactly one place
/// ([_matrix]) and is unit-testable without any UI.

/// Every capability granted to the currently signed-in staff member (empty when
/// locked). Watch this to gate UI reactively.
final capabilitiesProvider = Provider<Set<Capability>>((ref) {
  final role = ref.watch(currentStaffProvider)?.role;
  return role == null ? const {} : (capabilityMatrix[role] ?? const {});
});

/// Convenience: does the current staff member have [cap]?
final canProvider = Provider.family<bool, Capability>(
  (ref, cap) => ref.watch(capabilitiesProvider).contains(cap),
);
