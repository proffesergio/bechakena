import '../format.dart';
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
      );
}

/// Renders the monospaced receipt body. [width] is characters per line:
/// 32 for 58 mm paper, 48 for 80 mm.
///
/// Amounts print as "Tk" — cheap thermal printers have no ৳ glyph; Bangla
/// text on receipts arrives with bitmap rendering (roadmap).
String renderReceiptText(ReceiptData data, {int width = 32}) {
  final lines = <String>[];
  void center(String s) => lines.add(_center(_fit(s, width), width));
  void pair(String left, String right) => lines.add(_pair(left, right, width));
  void divider() => lines.add('-' * width);

  center(data.shopName);
  if (data.address != null) center(data.address!);
  if (data.phone != null) center(data.phone!);
  divider();
  pair(data.invoiceNo, _formatDateTime(data.dateTime));
  divider();
  for (final item in data.items) {
    lines.add(_fit(item.name, width));
    pair(
      ' ${item.qty.display} x ${formatAmount(item.unitPrice)}',
      formatAmount(item.lineTotal),
    );
  }
  divider();
  pair('SUBTOTAL', 'Tk ${formatAmount(data.subtotal)}');
  if (!data.discount.isZero) {
    pair('DISCOUNT', '-Tk ${formatAmount(data.discount)}');
  }
  if (!data.vat.isZero) pair('VAT (incl.)', 'Tk ${formatAmount(data.vat)}');
  pair('TOTAL', 'Tk ${formatAmount(data.total)}');
  pair('PAID', 'Tk ${formatAmount(data.paid)}');
  if (!data.due.isZero) pair('DUE', 'Tk ${formatAmount(data.due)}');
  if (!data.change.isZero) pair('CHANGE', 'Tk ${formatAmount(data.change)}');
  divider();
  if (data.footer != null) center(data.footer!);
  return lines.join('\n');
}

String _formatDateTime(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(dt.day)}/${two(dt.month)}/${dt.year % 100} '
      '${two(dt.hour)}:${two(dt.minute)}';
}

String _fit(String s, int width) => s.length <= width ? s : s.substring(0, width);

String _center(String s, int width) {
  final pad = (width - s.length) ~/ 2;
  return pad > 0 ? '${' ' * pad}$s' : s;
}

String _pair(String left, String right, int width) {
  final space = width - left.length - right.length;
  if (space < 1) {
    final trimmed = _fit(left, width - right.length - 1);
    return '$trimmed${' ' * (width - trimmed.length - right.length)}$right';
  }
  return '$left${' ' * space}$right';
}
