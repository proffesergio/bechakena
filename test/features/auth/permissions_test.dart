import 'package:bechakena/core/db/database.dart' show StaffRole;
import 'package:bechakena/features/auth/logic/permissions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('role → capability matrix', () {
    test('owner has every capability', () {
      for (final cap in Capability.values) {
        expect(can(StaffRole.owner, cap), isTrue, reason: '$cap');
      }
    });

    test('manager runs the shop but not the danger zone', () {
      const allowed = {
        Capability.sell,
        Capability.manageCustomers,
        Capability.manageProducts,
        Capability.managePurchases,
        Capability.manageInventory,
        Capability.viewReports,
        Capability.processReturns,
        Capability.manageShopProfile,
        Capability.addCashier,
      };
      for (final cap in Capability.values) {
        expect(can(StaffRole.manager, cap), allowed.contains(cap),
            reason: '$cap');
      }
      // Explicitly owner-only.
      expect(can(StaffRole.manager, Capability.manageStaff), isFalse);
      expect(can(StaffRole.manager, Capability.manageBranches), isFalse);
      expect(can(StaffRole.manager, Capability.backupRestore), isFalse);
      expect(can(StaffRole.manager, Capability.clearData), isFalse);
      expect(can(StaffRole.manager, Capability.switchModule), isFalse);
    });

    test('cashier can only sell and manage customers', () {
      const allowed = {Capability.sell, Capability.manageCustomers};
      for (final cap in Capability.values) {
        expect(can(StaffRole.cashier, cap), allowed.contains(cap),
            reason: '$cap');
      }
    });

    test('a null (locked / signed-out) role can do nothing', () {
      for (final cap in Capability.values) {
        expect(can(null, cap), isFalse, reason: '$cap');
      }
    });
  });
}
