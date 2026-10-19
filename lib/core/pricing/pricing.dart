import '../money.dart';
import '../qty.dart';

/// Shared line pricing, used by carts, persisted drafts and order summaries.
Money linePrice({
  required Money unitPrice,
  required Qty qty,
  Money discount = Money.zero,
}) => unitPrice.timesQty(qty) - discount;

class TaxableAmount {
  const TaxableAmount(this.gross, this.rateBp);
  final Money gross;
  final int rateBp;
}

/// Allocate the bill discount proportionally with cumulative integer rounding.
/// Allocations sum exactly to the discount, even for mixed-tax baskets.
Money includedTax(
  Iterable<TaxableAmount> lines, {
  Money billDiscount = Money.zero,
}) {
  final list = lines.toList();
  final subtotal = list.fold(0, (int n, line) => n + line.gross.paisa);
  if (subtotal <= 0) return Money.zero;
  final discount = billDiscount.paisa.clamp(0, subtotal);
  var cumulative = 0;
  var allocated = 0;
  var result = Money.zero;
  for (final line in list) {
    cumulative += line.gross.paisa;
    final nextAllocated = (discount * cumulative) ~/ subtotal;
    final net = Money(line.gross.paisa - (nextAllocated - allocated));
    result += net.vatPortionInclusive(line.rateBp);
    allocated = nextAllocated;
  }
  return result;
}
