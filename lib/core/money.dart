import 'qty.dart';

/// Integer-paisa money type. All monetary values in the app are [Money];
/// doubles are never used for money (hard rule — see docs/DESIGN.md).
///
/// Percentages (VAT, discounts) are expressed in basis points:
/// 15% = 1500 bp. Prices are VAT-inclusive; use [vatPortionInclusive] /
/// [netOfVat] to split a gross amount for reporting.
extension type const Money(int paisa) {
  static const Money zero = Money(0);

  Money.fromTaka(int taka) : this(taka * 100);

  /// Parses user input: "125", "125.5", "৳1,250.50", Bangla digits "১২৫.৫০".
  /// Throws [FormatException] on anything that is not a money amount.
  factory Money.parse(String input) {
    var s = input
        .trim()
        .replaceAll('৳', '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .replaceAllMapped(
          RegExp('[০-৯]'),
          (m) => String.fromCharCode(m[0]!.codeUnitAt(0) - 0x09E6 + 0x30),
        );
    final match = RegExp(r'^(-?)(\d+)(?:\.(\d{1,2}))?$').firstMatch(s);
    if (match == null) {
      throw FormatException('Not a money amount', input);
    }
    final taka = int.parse(match.group(2)!);
    final decimals = match.group(3) ?? '';
    final paisaPart = decimals.isEmpty ? 0 : int.parse(decimals.padRight(2, '0'));
    final total = taka * 100 + paisaPart;
    return Money(match.group(1) == '-' ? -total : total);
  }

  int get taka => paisa ~/ 100;
  int get paisaPart => paisa.remainder(100);
  bool get isNegative => paisa < 0;
  bool get isZero => paisa == 0;

  Money operator +(Money other) => Money(paisa + other.paisa);
  Money operator -(Money other) => Money(paisa - other.paisa);
  Money operator -() => Money(-paisa);
  Money operator *(int qty) => Money(paisa * qty);
  bool operator <(Money other) => paisa < other.paisa;
  bool operator <=(Money other) => paisa <= other.paisa;
  bool operator >(Money other) => paisa > other.paisa;
  bool operator >=(Money other) => paisa >= other.paisa;

  /// [basisPoints] of this amount, rounded half away from zero.
  Money percent(int basisPoints) => Money(_divRound(paisa * basisPoints, 10000));

  /// VAT contained in this VAT-inclusive gross amount at [vatBasisPoints].
  Money vatPortionInclusive(int vatBasisPoints) =>
      Money(_divRound(paisa * vatBasisPoints, 10000 + vatBasisPoints));

  /// Price × quantity, rounded half away from zero:
  /// 1.5 kg (Qty 1500) at ৳80.00/kg → ৳120.00.
  Money timesQty(Qty qty) => Money(_divRound(paisa * qty.milli, 1000));

  /// Net (ex-VAT) part of this gross amount. Always satisfies
  /// `vatPortionInclusive(bp) + netOfVat(bp) == this`.
  Money netOfVat(int vatBasisPoints) => this - vatPortionInclusive(vatBasisPoints);

  /// Canonical unsigned-symbol decimal form, e.g. "125.50", "-0.05".
  String get asDecimalString {
    final abs = paisa.abs();
    final sign = paisa < 0 ? '-' : '';
    return '$sign${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
  }
}

/// Integer division rounding half away from zero (commercial rounding).
int _divRound(int a, int b) {
  final quotient = a ~/ b;
  final remainder = (a - quotient * b).abs();
  if (remainder * 2 >= b.abs()) {
    return quotient + (a.isNegative == b.isNegative ? 1 : -1);
  }
  return quotient;
}
