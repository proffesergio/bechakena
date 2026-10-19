import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Localised label for an order type ("Dine-in" / "Takeaway" / "Delivery").
String orderTypeLabel(AppLocalizations l10n, OrderType type) => switch (type) {
      OrderType.dineIn => l10n.orderTypeDineIn,
      OrderType.takeaway => l10n.orderTypeTakeaway,
      OrderType.delivery => l10n.orderTypeDelivery,
    };

/// Pre-VAT line sum of a running order (prices are VAT-inclusive; the VAT is
/// shown as the contained portion, consistent with the POS checkout).
Money subtotalOfItems(List<DineOrderItem> items) => items.fold(
    Money.zero, (sum, i) => sum + i.unitPrice.timesQty(i.qty));

Money vatOfItems(List<DineOrderItem> items) => items.fold(
    Money.zero,
    (sum, i) =>
        sum + i.unitPrice.timesQty(i.qty).vatPortionInclusive(i.vatRateBp));
