import 'package:drift/drift.dart';

import '../../money.dart';
import '../database.dart';

part 'customers_dao.g.dart';

@DriftAccessor(tables: [Customers, Sales, DuePayments])
class CustomersDao extends DatabaseAccessor<AppDatabase>
    with _$CustomersDaoMixin {
  CustomersDao(super.db);

  Future<Customer> insertCustomer(CustomersCompanion entry) =>
      into(customers).insertReturning(entry);

  Stream<List<Customer>> watchAll() => (select(customers)
        ..where((c) => c.deletedAt.isNull())
        ..orderBy([(c) => OrderingTerm.asc(c.name)]))
      .watch();

  /// Baki balance — derived: SUM(sales.due) − SUM(due_payments.amount).
  Future<Money> dueFor(String customerId) async {
    final dueSum = sales.due.sum();
    final salesQuery = selectOnly(sales)
      ..addColumns([dueSum])
      ..where(sales.customerId.equals(customerId));
    final salesRow = await salesQuery.getSingle();

    final paidSum = duePayments.amount.sum();
    final paymentsQuery = selectOnly(duePayments)
      ..addColumns([paidSum])
      ..where(duePayments.customerId.equals(customerId));
    final paymentsRow = await paymentsQuery.getSingle();

    return Money((salesRow.read(dueSum) ?? 0) - (paymentsRow.read(paidSum) ?? 0));
  }

  Future<DuePayment> addDuePayment({
    required String customerId,
    required Money amount,
    required PayMethod method,
    String? note,
  }) =>
      into(duePayments).insertReturning(DuePaymentsCompanion.insert(
        customerId: customerId,
        amount: amount,
        method: method,
        note: Value(note),
      ));
}
