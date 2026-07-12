/// Integer milli-unit quantity: 1 pc = 1000, 250 g = 250 when the unit is kg.
/// Keeps fractional quantities (kg, litre) exact — stock is SUM of these
/// deltas, so floats are as forbidden here as they are for money.
extension type const Qty(int milli) {
  static const Qty zero = Qty(0);

  Qty.fromCount(int count) : this(count * 1000);

  /// Parses "3", "1.5", "0.250", Bangla digits "১.৫" (max 3 decimals).
  factory Qty.parse(String input) {
    final s = input.trim().replaceAllMapped(
          RegExp('[০-৯]'),
          (m) => String.fromCharCode(m[0]!.codeUnitAt(0) - 0x09E6 + 0x30),
        );
    final match = RegExp(r'^(-?)(\d+)(?:\.(\d{1,3}))?$').firstMatch(s);
    if (match == null) {
      throw FormatException('Not a quantity', input);
    }
    final whole = int.parse(match.group(2)!);
    final decimals = match.group(3) ?? '';
    final frac = decimals.isEmpty ? 0 : int.parse(decimals.padRight(3, '0'));
    final total = whole * 1000 + frac;
    return Qty(match.group(1) == '-' ? -total : total);
  }

  bool get isNegative => milli < 0;
  bool get isZero => milli == 0;

  Qty operator +(Qty other) => Qty(milli + other.milli);
  Qty operator -(Qty other) => Qty(milli - other.milli);
  Qty operator -() => Qty(-milli);
  bool operator <(Qty other) => milli < other.milli;
  bool operator <=(Qty other) => milli <= other.milli;
  bool operator >(Qty other) => milli > other.milli;
  bool operator >=(Qty other) => milli >= other.milli;

  /// "3", "1.5", "0.25" — trailing zeros trimmed.
  String get display {
    final abs = milli.abs();
    final sign = milli < 0 ? '-' : '';
    final whole = abs ~/ 1000;
    final frac = (abs % 1000)
        .toString()
        .padLeft(3, '0')
        .replaceFirst(RegExp(r'0+$'), '');
    return frac.isEmpty ? '$sign$whole' : '$sign$whole.$frac';
  }
}
