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

  /// Customers readable under [branchId] (null = every branch, the owner's
  /// head-office view). Staff see customers who can transact at their counter:
  /// those without branch-attributable sales yet, plus those who have already
  /// sold there. Customers whose finalized sales all belong to another outlet
  /// stay hidden — the read-path ownership guard for baki dialogs.
  Stream<List<Customer>> watchAll({String? branchId}) {
    final query = select(customers)
      ..where((c) => c.deletedAt.isNull())
      ..orderBy([(c) => OrderingTerm.asc(c.name)]);
    if (branchId != null) {
      query.where((_) => _soldElsewhere(branchId).not() | _soldHere(branchId));
    }
    return query.watch();
  }

  Expression<bool> _soldHere(String branchId) =>
      existsQuery(selectOnly(sales)
        ..addColumns([sales.id])
        ..where(sales.customerId.equalsExp(customers.id) &
            sales.branchId.equals(branchId) &
            sales.deletedAt.isNull() &
            sales.status.equalsValue(SaleStatus.finalized)));

  Expression<bool> _soldElsewhere(String branchId) =>
      existsQuery(selectOnly(sales)
        ..addColumns([sales.id])
        ..where(sales.customerId.equalsExp(customers.id) &
            sales.branchId.isNotNull() &
            sales.branchId.equals(branchId).not() &
            sales.deletedAt.isNull() &
            sales.status.equalsValue(SaleStatus.finalized)));

  /// Baki balance — derived: SUM(sales.due) − SUM(due_payments.amount).
  Future<Money> dueFor(String customerId) async {
    final dueSum = sales.due.sum();
    final salesQuery = selectOnly(sales)
      ..addColumns([dueSum])
      ..where(sales.customerId.equals(customerId) &
          sales.deletedAt.isNull() &
          sales.status.equalsValue(SaleStatus.finalized));
    final salesRow = await salesQuery.getSingle();

    final paidSum = duePayments.amount.sum();
    final paymentsQuery = selectOnly(duePayments)
      ..addColumns([paidSum])
      ..where(duePayments.customerId.equals(customerId) &
          duePayments.deletedAt.isNull());
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
