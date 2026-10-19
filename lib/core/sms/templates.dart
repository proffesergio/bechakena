import '../format.dart';
import '../money.dart';
import '../currency.dart';

/// Renders an amount for SMS: en uses ASCII "Tk 1,250.00" (widest gateway
/// compatibility); bn uses ৳ with Bangla digits (Unicode SMS).
String _smsAmount(Money amount, String locale, ShopCurrency currency) =>
    locale.startsWith('bn')
    ? formatTaka(amount, locale: 'bn', currency: currency)
    : '${currency == ShopCurrency.bdt ? 'Tk' : currency.code} ${formatAmount(amount, currency: currency)}';

/// Due (baki) reminder to a customer.
String renderDueReminderSms({
  required String shopName,
  required String customerName,
  required Money due,
  String locale = 'en',
  ShopCurrency currency = ShopCurrency.bdt,
}) {
  final amount = _smsAmount(due, locale, currency);
  if (locale.startsWith('bn')) {
    return 'প্রিয় $customerName, $shopName-এ আপনার বাকি $amount। '
        'অনুগ্রহ করে পরিশোধ করুন। ধন্যবাদ।';
  }
  return 'Dear $customerName, your due at $shopName is $amount. '
      'Please clear it soon. Thank you.';
}

/// Post-sale receipt confirmation, with a due clause only when money is owed.
String renderReceiptSms({
  required String shopName,
  required String invoiceNo,
  required Money total,
  required Money due,
  String locale = 'en',
  ShopCurrency currency = ShopCurrency.bdt,
}) {
  final totalStr = _smsAmount(total, locale, currency);
  if (locale.startsWith('bn')) {
    final dueClause = due > Money.zero
        ? ' বাকি: ${_smsAmount(due, locale, currency)}।'
        : '';
    return '$shopName: চালান $invoiceNo, মোট $totalStr।$dueClause ধন্যবাদ!';
  }
  final dueClause = due > Money.zero
      ? ' Due: ${_smsAmount(due, locale, currency)}.'
      : '';
  return '$shopName: received $totalStr for invoice $invoiceNo.$dueClause '
      'Thank you!';
}
