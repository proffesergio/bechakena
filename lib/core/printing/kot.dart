import '../qty.dart';

/// One line on a kitchen order ticket — no prices, just what to cook.
class KotLine {
  const KotLine({required this.name, required this.qty, this.note});
  final String name;
  final Qty qty;
  final String? note;
}

/// Renders a monospaced Kitchen Order Ticket (KOT). Unlike a receipt it carries
/// no money — only the station, order label and what to prepare — so the
/// kitchen can start cooking the moment the waiter fires the order.
String renderKotText({
  required String title,
  required String orderLabel,
  required DateTime at,
  required List<KotLine> items,
  int width = 32,
}) {
  final lines = <String>[];
  lines.add(_center(_fit(title, width), width));
  lines.add('-' * width);
  lines.add(_fit(orderLabel, width));
  lines.add(_fit(_formatDateTime(at), width));
  lines.add('-' * width);
  for (final item in items) {
    lines.add(_fit('${item.qty.display} x ${item.name}', width));
    if (item.note != null && item.note!.trim().isNotEmpty) {
      lines.add(_fit('   * ${item.note!.trim()}', width));
    }
  }
  lines.add('-' * width);
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
