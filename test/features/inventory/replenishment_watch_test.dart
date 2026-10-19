import 'dart:async';

import 'package:bechakena/core/db/database.dart';
import 'package:bechakena/core/db/sale_draft.dart';
import 'package:bechakena/core/money.dart';
import 'package:bechakena/core/qty.dart';
import 'package:bechakena/features/inventory/logic/replenishment_provider.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'active plan includes new sales only from its outlet and rolling window',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final local = await db
          .into(db.shops)
          .insertReturning(ShopsCompanion.insert(name: 'Local'));
      final other = await db
          .into(db.shops)
          .insertReturning(ShopsCompanion.insert(name: 'Other'));
      final product = await db.productsDao.insertProduct(
        ProductsCompanion.insert(
          name: 'Rice',
          salePrice: const Money(100),
          unit: const Value('kg'),
          lowStockLevel: const Value(Qty(1000)),
        ),
      );

      Future<void> sell(String branch, {DateTime? at, int milli = 1000}) async {
        await db.salesDao.finalizeSale(
          invoicePrefix: 'BK',
          branchId: branch,
          now: at,
          items: [
            SaleDraftItem(
              productId: product.id,
              nameSnapshot: product.name,
              qty: Qty(milli),
              unitPrice: const Money(100),
            ),
          ],
          tenders: const [
            TenderDraft(method: PayMethod.cash, amount: Money(10000)),
          ],
        );
      }

      final now = DateTime.now().toUtc();
      await sell(local.id, at: now.subtract(const Duration(days: 29)));
      await sell(local.id, at: now.add(const Duration(days: 1)));
      final initial = Completer<List<ReplenishmentRow>>();
      final refreshed = Completer<List<ReplenishmentRow>>();
      final subscription =
          watchReplenishment(
            db,
            branchId: local.id,
            catalogScope: 'superShop',
            window: (leadDays: 7, coverDays: 14),
          ).listen((rows) {
            if (!initial.isCompleted) initial.complete(rows);
            if (rows.single.sold.milli > 0 && !refreshed.isCompleted) {
              refreshed.complete(rows);
            }
          });
      addTearDown(subscription.cancel);
      expect(
        (await initial.future.timeout(const Duration(seconds: 5))).single.sold,
        Qty.zero,
      );

      // Keep the same watch alive while both outlets sell. The remote sale and
      // old/future local sales must not contribute to recent local demand.
      await sell(other.id, milli: 2000);
      await sell(local.id);
      final rows = await refreshed.future.timeout(const Duration(seconds: 5));
      expect(rows.single.sold, const Qty(1000));
      expect(rows.single.stock, const Qty(-3000));
    },
  );
}
