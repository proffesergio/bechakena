import '../currency.dart';
import '../money.dart';
import '../qty.dart';

/// One printed line item.
class ReceiptItem {
  const ReceiptItem({
    required this.name,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String name;
  final Qty qty;
  final Money unitPrice;
  final Money lineTotal;
}

/// Everything needed to render a receipt, independent of DB row types.
class ReceiptData {
  const ReceiptData({
    required this.shopName,
    this.address,
    this.phone,
    required this.invoiceNo,
    required this.dateTime,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.vat,
    required this.total,
    required this.paid,
    required this.due,
    required this.change,
    this.footer,
    this.currency = ShopCurrency.bdt,
    this.taxLabel = 'VAT',
    this.taxId = '',
  });

  final String shopName;
  final String? address;
  final String? phone;
  final String invoiceNo;
  final DateTime dateTime;
  final List<ReceiptItem> items;
  final Money subtotal;
  final Money discount;
  final Money vat;
  final Money total;
  final Money paid;
  final Money due;
  final Money change;
  final String? footer;
  final ShopCurrency currency;
  final String taxLabel;
  final String taxId;

  ReceiptData copyWith({Money? paid, Money? due, Money? change}) => ReceiptData(
    shopName: shopName,
    address: address,
    phone: phone,
    invoiceNo: invoiceNo,
    dateTime: dateTime,
    items: items,
    subtotal: subtotal,
    discount: discount,
    vat: vat,
    total: total,
    paid: paid ?? this.paid,
    due: due ?? this.due,
    change: change ?? this.change,
    footer: footer,
    currency: currency,
    taxLabel: taxLabel,
    taxId: taxId,
  );
}
