import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/business_type.dart';
import '../../../app/providers.dart';
import '../../../core/qty.dart';
import '../../../core/db/database.dart';
import '../../auth/logic/permissions.dart';
import 'replenishment.dart';

typedef ReplenishmentWindow = ({int leadDays, int coverDays});

class ReplenishmentRow {
  const ReplenishmentRow({
    required this.name,
    required this.unit,
    required this.stock,
    required this.sold,
    required this.plan,
  });
  final String name;
  final String unit;
  final Qty stock;
  final Qty sold;
  final ReplenishmentPlan plan;
}

final replenishmentProvider = StreamProvider.autoDispose
    .family<List<ReplenishmentRow>, ReplenishmentWindow>((ref, window) {
      if (!ref.watch(canProvider(Capability.manageInventory))) {
        return Stream.value(const []);
      }
      final branch = ref.watch(currentBranchProvider);
      if (branch == null || branch.isEmpty) return Stream.value(const []);
      final scope = ref.watch(catalogScopeProvider);
      final db = ref.watch(databaseProvider);
      return watchReplenishment(
        db,
        branchId: branch,
        catalogScope: scope,
        window: window,
      );
    });

/// Watch the current outlet's plan. SQLite evaluates the rolling window again
/// on each table change, so sales created after subscription enter demand.
Stream<List<ReplenishmentRow>> watchReplenishment(
  AppDatabase db, {
  required String branchId,
  required String catalogScope,
  required ReplenishmentWindow window,
}) {
  // Correlated subqueries avoid multiplying movement quantities by sale lines.
  // All user/session values are bound; no dynamic SQL identifiers.
  return db
      .customSelect(
        '''
    SELECT p.name, p.unit, p.low_stock_level,
      COALESCE((SELECT SUM(m.qty_delta) FROM stock_movements m
        WHERE m.product_id = p.id AND m.branch_id = ?
          AND m.deleted_at IS NULL), 0) AS stock_milli,
      COALESCE((SELECT SUM(i.qty) FROM sale_items i
        JOIN sales s ON s.id = i.sale_id
        WHERE i.product_id = p.id AND s.branch_id = ?
          AND s.status = 'finalized'
          AND s.created_at >= CAST(strftime('%s', 'now') AS INTEGER) - 28 * 86400
          AND s.created_at < CAST(strftime('%s', 'now') AS INTEGER) + 1
          AND s.deleted_at IS NULL AND i.deleted_at IS NULL), 0) AS sold_milli
    FROM products p WHERE p.deleted_at IS NULL AND p.is_active = 1
      AND p.business_type = ? ORDER BY p.name
  ''',
        variables: [
          Variable(branchId),
          Variable(branchId),
          Variable(catalogScope),
        ],
        readsFrom: {db.products, db.stockMovements, db.saleItems, db.sales},
      )
      .watch()
      .map((rows) {
        final result = <ReplenishmentRow>[];
        for (final row in rows) {
          final stock = Qty(row.read<int>('stock_milli'));
          final sold = Qty(row.read<int>('sold_milli'));
          final unit = row.read<String>('unit');
          final plan = planReplenishment(
            stock: stock,
            sold: sold,
            minimum: Qty(row.read<int>('low_stock_level')),
            leadDays: window.leadDays,
            coverDays: window.coverDays,
            wholeUnits: {
              'pcs',
              'pc',
              'piece',
              'pieces',
              'unit',
            }.contains(unit.toLowerCase()),
          );
          if (!plan.suggested.isZero) {
            result.add(
              ReplenishmentRow(
                name: row.read<String>('name'),
                unit: unit,
                stock: stock,
                sold: sold,
                plan: plan,
              ),
            );
          }
        }
        result.sort(
          (a, b) => (a.plan.daysRemaining ?? 1000000).compareTo(
            b.plan.daysRemaining ?? 1000000,
          ),
        );
        return result;
      });
}
