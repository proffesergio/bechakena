import 'money.dart';
import 'currency.dart';

const _banglaDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

/// Replaces every ASCII digit with its Bangla equivalent.
String toBanglaDigits(String input) => input.replaceAllMapped(
      RegExp(r'[0-9]'),
      (m) => _banglaDigits[m[0]!.codeUnitAt(0) - 0x30],
    );

/// Formats [amount] as taka with the ৳ sign and Bangladeshi lakh grouping
/// (last three digits, then groups of two): ৳1,23,45,678.90.
/// A `bn` locale additionally renders Bangla digits.
String formatTaka(Money amount, {String locale = 'en', ShopCurrency currency = ShopCurrency.bdt}) {
  final abs = amount.paisa.abs();
  final grouped = _group((abs ~/ 100).toString(), currency);
  final decimals = (abs % 100).toString().padLeft(2, '0');
  var result = '${currency.symbol}$grouped.$decimals';
  if (locale.startsWith('bn')) result = toBanglaDigits(result);
  return amount.isNegative ? '-$result' : result;
}

/// Grouped decimal amount without currency symbol or Bangla digits —
/// e.g. 1,23,456.78. Used on thermal receipts (ASCII only).
String formatAmount(Money amount, {ShopCurrency currency = ShopCurrency.bdt}) {
  final abs = amount.paisa.abs();
  final grouped = _group((abs ~/ 100).toString(), currency);
  final decimals = (abs % 100).toString().padLeft(2, '0');
  return '${amount.isNegative ? '-' : ''}$grouped.$decimals';
}

String _group(String digits, ShopCurrency currency) {
  if (currency.lakhGrouping) return _lakhGroup(digits);
  return digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
}

String _lakhGroup(String digits) {
  if (digits.length <= 3) return digits;
  final groups = <String>[digits.substring(digits.length - 3)];
  var rest = digits.substring(0, digits.length - 3);
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  groups.insert(0, rest);
  return groups.join(',');
}
