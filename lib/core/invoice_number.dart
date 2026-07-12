/// Human-readable invoice numbers: `PREFIX[device]-YYMMDD-SEQ`.
///
/// The daily sequence restarts every day; [deviceNo] joins the prefix only
/// for multi-device shops (deviceNo > 0) so numbers stay collision-free when
/// several offline devices sell simultaneously under the Cloud Plan.
String formatInvoiceNo({
  required String prefix,
  required DateTime date,
  required int seq,
  int deviceNo = 0,
}) {
  final devicePrefix = deviceNo > 0 ? '$prefix$deviceNo' : prefix;
  final yy = (date.year % 100).toString().padLeft(2, '0');
  final mm = date.month.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');
  return '$devicePrefix-$yy$mm$dd-${seq.toString().padLeft(4, '0')}';
}
