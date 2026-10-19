import '../format.dart';
import '../currency.dart';
import '../money.dart';
import 'receipt_data.dart';
export 'receipt_data.dart';

/// Renders the monospaced receipt body. [width] is characters per line:
/// 32 for 58 mm paper, 48 for 80 mm.
///
/// Amounts print as "Tk". The print service shapes Unicode lines as bitmaps.
String renderReceiptText(ReceiptData data, {int width = 32}) {
  final lines = <String>[];
  void center(String s) => lines.add(_center(_fit(s, width), width));
  void pair(String left, String right) => lines.add(_pair(left, right, width));
  void divider() => lines.add('-' * width);

  String amount(Money value) => formatAmount(value, currency: data.currency);
  final code = data.currency == ShopCurrency.bdt ? 'Tk' : data.currency.code;
  center(data.shopName);
  if (data.taxId.isNotEmpty) center('${data.taxLabel} ID: ${data.taxId}');
  if (data.address != null) center(data.address!);
  if (data.phone != null) center(data.phone!);
  divider();
  pair(data.invoiceNo, _formatDateTime(data.dateTime));
  divider();
  for (final item in data.items) {
    lines.add(_fit(item.name, width));
    pair(
      ' ${item.qty.display} x ${amount(item.unitPrice)}',
      amount(item.lineTotal),
    );
  }
  divider();
  pair('SUBTOTAL', '$code ${amount(data.subtotal)}');
  if (!data.discount.isZero) {
    pair('DISCOUNT', '-$code ${amount(data.discount)}');
  }
  if (!data.vat.isZero)
    pair('${data.taxLabel} (incl.)', '$code ${amount(data.vat)}');
  pair('TOTAL', '$code ${amount(data.total)}');
  pair('PAID', '$code ${amount(data.paid)}');
  if (!data.due.isZero) pair('DUE', '$code ${amount(data.due)}');
  if (!data.change.isZero) pair('CHANGE', '$code ${amount(data.change)}');
  divider();
  if (data.footer != null) center(data.footer!);
  return lines.join('\n');
}

String _formatDateTime(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(dt.day)}/${two(dt.month)}/${dt.year % 100} '
      '${two(dt.hour)}:${two(dt.minute)}';
}

String _fit(String s, int width) =>
    s.codeUnits.any((unit) => unit > 0x7f) || s.length <= width
    ? s
    : s.substring(0, width);

String _center(String s, int width) {
  final pad = (width - s.length) ~/ 2;
  return pad > 0 ? '${' ' * pad}$s' : s;
}

String _pair(String left, String right, int width) {
  final space = width - left.length - right.length;
  if (space < 1) {
    if (left.codeUnits.any((unit) => unit > 0x7f) || right.length >= width) {
      return '$left\n${right.padLeft(width)}';
    }
    final trimmed = _fit(left, width - right.length - 1);
    return '$trimmed${' ' * (width - trimmed.length - right.length)}$right';
  }
  return '$left${' ' * space}$right';
}
