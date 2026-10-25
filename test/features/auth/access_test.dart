import 'package:bechakena/core/db/database.dart';
import 'package:bechakena/core/db/sale_draft.dart';
import 'package:bechakena/core/money.dart';
import 'package:bechakena/core/qty.dart';
import 'package:bechakena/features/auth/logic/access.dart';
import 'package:bechakena/features/auth/logic/permissions.dart';
import 'package:bechakena/app/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression tests for the authorisation audit (round 2): branch-attributed
/// read paths must be scoped to the session's branch for every role below
/// owner, so a record id alone can never expose another outlet's sales,
/// purchases or customer baki.
void main() {
  group('canViewBranch', () {
    test('owner scope (null) reads every branch', () {
      expect(canViewBranch(null, 'branch-a'), isTrue);
      expect(canViewBranch(null, null), isTrue);
    });

    test('staff scope reads only its own branch', () {
      expect(canViewBranch('branch-a', 'branch-a'), isTrue);
      expect(canViewBranch('branch-a', null), isFalse);
      expect(canViewBranch('', 'branch-a'), isFalse);
      expect(canViewBranch('', null), isFalse);
    });

    test('staff scope refuses other branches', () {
      expect(canViewBranch('branch-a', 'branch-b'), isFalse);
    });
  });

  group('branch-scoped reads', () {
    late AppDatabase db;
    late String branchA;
    late String branchB;
    final now = DateTime.now().toUtc();

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      branchA =
          (await db
                  .into(db.shops)
                  .insertReturning(ShopsCompanion.insert(name: 'Outlet A')))
              .id;
      branchB =
          (await db
                  .into(db.shops)
                  .insertReturning(ShopsCompanion.insert(name: 'Outlet B')))
              .id;
    });
    tearDown(() async => db.close());

    Future<Sale> sellAt(String branchId, {String? customerId}) async {
      final product = await db.productsDao.insertProduct(
        ProductsCompanion.insert(name: 'Rice', salePrice: const Money(10000)),
      );
      return db.salesDao.finalizeSale(
        invoicePrefix: 'BK',
        branchId: branchId,
        customerId: customerId,
        items: [
          SaleDraftItem(
            productId: product.id,
            nameSnapshot: 'Rice',
            qty: const Qty(1000),
            unitPrice: const Money(10000),
          ),
        ],
        tenders: [
          TenderDraft(method: PayMethod.cash, amount: const Money(10000)),
        ],
        now: now,
      );
    }

    Future<Purchase> buyAt(String branchId) async {
      final product = await db.productsDao.insertProduct(
        ProductsCompanion.insert(name: 'Oil', salePrice: const Money(5000)),
      );
      return db.purchasesDao.createPurchase(
        branchId: branchId,
        items: [
          PurchaseDraftItem(
            productId: product.id,
            qty: const Qty(1000),
            unitCost: const Money(4000),
          ),
        ],
      );
    }

    test('watchRecent(branchId) keeps only that outlet\'s sales', () async {
      final a = await sellAt(branchA);
      await sellAt(branchB);

      final scoped = await db.salesDao.watchRecent(branchId: branchA).first;
      expect(scoped.map((s) => s.id), [a.id]);
      expect((await db.salesDao.watchRecent().first).length, 2);
    });

    test('watchRecent(branchId) keeps only that outlet\'s purchases', () async {
      final a = await buyAt(branchA);
      await buyAt(branchB);

      final scoped = await db.purchasesDao.watchRecent(branchId: branchA).first;
      expect(scoped.map((p) => p.id), [a.id]);
      expect((await db.purchasesDao.watchRecent().first).length, 2);
    });

    test('watchAll(branchId) hides customers sold to only elsewhere', () async {
      final local = await db.customersDao.insertCustomer(
        CustomersCompanion.insert(name: 'Local'),
      );
      final remote = await db.customersDao.insertCustomer(
        CustomersCompanion.insert(name: 'Remote'),
      );
      await db.customersDao.insertCustomer(
        CustomersCompanion.insert(name: 'New walk-in'),
      );

      await sellAt(branchA, customerId: local.id);
      await sellAt(branchB, customerId: remote.id);

      final visible = await db.customersDao.watchAll(branchId: branchA).first;
      final names = visible.map((c) => c.name).toSet();
      expect(names, containsAll(['Local', 'New walk-in']));
      expect(names, isNot(contains('Remote')));

      expect((await db.customersDao.watchAll().first).length, 3);
    });

    test('a customer sold at both outlets stays visible at both', () async {
      final shared = await db.customersDao.insertCustomer(
        CustomersCompanion.insert(name: 'Shared'),
      );
      await sellAt(branchA, customerId: shared.id);
      await sellAt(branchB, customerId: shared.id);

      for (final branch in [branchA, branchB]) {
        final visible = await db.customersDao.watchAll(branchId: branch).first;
        expect(visible.map((c) => c.id), [shared.id]);
      }
    });

    test(
      'customer dialog policy fails closed and reacts to revoked access',
      () async {
        final local = await db.customersDao.insertCustomer(
          CustomersCompanion.insert(name: 'Local'),
        );
        final remote = await db.customersDao.insertCustomer(
          CustomersCompanion.insert(name: 'Remote'),
        );
        await sellAt(branchA, customerId: local.id);
        await sellAt(branchB, customerId: remote.id);
        var allowed = true;
        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            readScopeBranchProvider.overrideWithValue(branchA),
            capabilitiesProvider.overrideWith(
              (ref) => allowed ? {Capability.manageCustomers} : {},
            ),
          ],
        );
        addTearDown(container.dispose);
        // Riverpod pauses streams without listeners; model the dialog's watch.
        final subscription = container.listen(
          canManageCustomerProvider(local.id),
          (_, _) {},
        );
        addTearDown(subscription.close);
        expect(container.read(canManageCustomerProvider(local.id)), isFalse);
        await container.read(scopedCustomersProvider.future);
        expect(container.read(canManageCustomerProvider(local.id)), isTrue);
        expect(container.read(canManageCustomerProvider(remote.id)), isFalse);
        allowed = false;
        container.invalidate(capabilitiesProvider);
        expect(container.read(canManageCustomerProvider(local.id)), isFalse);
      },
    );
  });
}
