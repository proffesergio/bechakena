import 'package:drift/drift.dart';

import '../money.dart';
import '../qty.dart';

class MoneyConverter extends TypeConverter<Money, int> {
  const MoneyConverter();

  @override
  Money fromSql(int fromDb) => Money(fromDb);

  @override
  int toSql(Money value) => value.paisa;
}

class QtyConverter extends TypeConverter<Qty, int> {
  const QtyConverter();

  @override
  Qty fromSql(int fromDb) => Qty(fromDb);

  @override
  int toSql(Qty value) => value.milli;
}
