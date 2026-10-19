/// Supported shop accounting currencies. All amounts use exactly 100 minor
/// units per major unit. Choosing one never performs foreign exchange.
enum ShopCurrency {
  bdt('BDT', '৳', lakhGrouping: true),
  usd('USD', r'$'),
  eur('EUR', '€'),
  gbp('GBP', '£'),
  aed('AED', 'AED '),
  sar('SAR', 'SAR '),
  inr('INR', '₹', lakhGrouping: true),
  cad('CAD', 'CA\$'),
  aud('AUD', 'A\$'),
  sgd('SGD', 'S\$'),
  myr('MYR', 'RM '),
  pkr('PKR', 'PKR ', lakhGrouping: true);

  const ShopCurrency(this.code, this.symbol, {this.lakhGrouping = false});
  final String code;
  final String symbol;
  final bool lakhGrouping;

  /// Missing legacy configuration means BDT; unknown stored codes fail closed.
  static ShopCurrency decode(String? code) => code == null
      ? bdt
      : values.firstWhere((c) => c.code == code,
          orElse: () => throw FormatException('Unsupported currency', code));
}
