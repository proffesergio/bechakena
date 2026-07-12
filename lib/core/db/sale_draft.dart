import '../money.dart';
import '../qty.dart';
import 'tables.dart';

/// One cart line as assembled at the POS, before finalization.
class SaleDraftItem {
  const SaleDraftItem({
    this.productId,
    required this.nameSnapshot,
    required this.qty,
    required this.unitPrice,
    this.lineDiscount = Money.zero,
    this.vatRateBp = 0,
  });

  /// Null for manual (unlisted) items — no stock movement is written.
  final String? productId;
  final String nameSnapshot;
  final Qty qty;
  final Money unitPrice;
  final Money lineDiscount;
  final int vatRateBp;

  Money get lineTotal => unitPrice.timesQty(qty) - lineDiscount;

  /// VAT contained in this line (prices are VAT-inclusive).
  Money get vatPortion => lineTotal.vatPortionInclusive(vatRateBp);
}

/// Money actually handed over at checkout. Anything short of the bill total
/// becomes due (baki) on the attached customer.
class TenderDraft {
  const TenderDraft({required this.method, required this.amount, this.refNo});

  final PayMethod method;
  final Money amount;
  final String? refNo;
}
