import '../../../core/qty.dart';

/// Transparent, offline planning; no network, predictive model or stock writes.
class ReplenishmentPlan {
  const ReplenishmentPlan({required this.suggested, this.daysRemaining});
  final Qty suggested;
  final int? daysRemaining;
}

ReplenishmentPlan planReplenishment({
  required Qty stock,
  required Qty sold,
  required Qty minimum,
  int historyDays = 28,
  int leadDays = 7,
  int coverDays = 14,
  bool wholeUnits = false,
}) {
  if (historyDays < 1 ||
      leadDays < 0 ||
      coverDays < 1 ||
      sold.isNegative ||
      minimum.isNegative) {
    throw ArgumentError('Invalid replenishment inputs');
  }
  final horizon = leadDays + coverDays;
  final demand = (sold.milli * horizon + historyDays - 1) ~/ historyDays;
  final target = demand > minimum.milli ? demand : minimum.milli;
  var shortage = target - stock.milli;
  if (shortage < 0) shortage = 0;
  if (wholeUnits) shortage = ((shortage + 999) ~/ 1000) * 1000;
  return ReplenishmentPlan(
    suggested: Qty(shortage),
    daysRemaining: sold.isZero
        ? null
        : ((stock.milli < 0 ? 0 : stock.milli) * historyDays) ~/ sold.milli,
  );
}
