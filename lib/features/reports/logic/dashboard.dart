import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../../auth/logic/access.dart';

/// Selected report range (1 / 7 / 30 days), shared by the filter row and the
/// dashboard query.
class RangeDays extends Notifier<int> {
  @override
  int build() => 7;

  void set(int days) => state = days;
}

final rangeDaysProvider = NotifierProvider<RangeDays, int>(RangeDays.new);

/// Everything the dashboard renders, computed in one pass from the sale
/// aggregates for the selected range.
class DashboardData {
  const DashboardData({
    required this.days,
    required this.top,
    required this.payments,
    required this.staff,
    required this.refunds,
  });

  final List<DailyTotal> days;
  final List<TopProduct> top;
  final Map<PayMethod, Money> payments;
  final Map<String?, Money> staff;
  final Money refunds;

  Money get total => days.fold(Money.zero, (s, d) => s + d.total);
  int get count => days.fold(0, (s, d) => s + d.count);
  Money get avg => count == 0 ? Money.zero : Money(total.paisa ~/ count);
  Money get net => total - refunds;
}

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final db = ref.watch(databaseProvider);
  final rangeDays = ref.watch(rangeDaysProvider);
  final branchId = ref.watch(readScopeBranchProvider);
  final now = DateTime.now().toUtc();
  final end = DateTime.utc(now.year, now.month, now.day)
      .add(const Duration(days: 1));
  final start = end.subtract(Duration(days: rangeDays));
  final days = await db.salesDao.dailyTotals(start: start, end: end, branchId: branchId);
  final top = await db.salesDao.topProducts(start: start, end: end, branchId: branchId);
  final payments = await db.salesDao.paymentTotals(start: start, end: end, branchId: branchId);
  final staff = await db.salesDao.staffTotals(start: start, end: end, branchId: branchId);
  final refunds = await db.returnsDao.refundsInRange(start: start, end: end, branchId: branchId);
  return DashboardData(
      days: days,
      top: top,
      payments: payments,
      staff: staff,
      refunds: refunds);
});
