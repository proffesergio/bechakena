import 'package:drift/drift.dart';

import '../db/database.dart';
import '../db/sale_draft.dart';
import '../invoice_number.dart';
import '../money.dart';
import '../pricing/pricing.dart';

/// Validates and commits the sale, lines, tenders and stock ledger together.
/// The DAO keeps the public compatibility entrypoint and read queries.
class SaleFinalizer {
  const SaleFinalizer(this.db);
  final AppDatabase db;

  Future<Sale> finalize({
    required String invoicePrefix,
    int deviceNo = 0,
    String? staffId,
    String? customerId,
    required List<SaleDraftItem> items,
    required List<TenderDraft> tenders,
    Money billDiscount = Money.zero,
    DateTime? now,
    String? branchId,
  }) {
    if (items.isEmpty) throw StateError('Cannot finalize an empty sale');
    for (final line in items) {
      if (line.nameSnapshot.trim().isEmpty ||
          line.qty.milli <= 0 ||
          line.unitPrice.isNegative ||
          line.lineDiscount.isNegative ||
          line.lineTotal.isNegative ||
          line.vatRateBp < 0 ||
          line.vatRateBp > 10000) {
        throw ArgumentError('Invalid sale line');
      }
    }
    final subtotal = items.fold(
      Money.zero,
      (sum, line) => sum + line.lineTotal,
    );
    if (billDiscount.isNegative ||
        billDiscount > subtotal ||
        tenders.any((t) => t.amount.isNegative)) {
      throw ArgumentError('Invalid discount or tender');
    }
    final total = subtotal - billDiscount;
    final vat = includedTax(
      items.map((i) => TaxableAmount(i.lineTotal, i.vatRateBp)),
      billDiscount: billDiscount,
    );
    final tendered = tenders.fold(Money.zero, (sum, t) => sum + t.amount);
    final due = tendered < total ? total - tendered : Money.zero;
    if (!due.isZero && customerId == null) {
      throw ArgumentError('A sale with due must be attached to a customer');
    }
    final at = (now ?? DateTime.now()).toUtc();
    return db.transaction(() async {
      final branch = branchId ?? await db.currentBranchId();
      final start = DateTime.utc(at.year, at.month, at.day);
      final count = db.sales.id.count();
      final query = db.selectOnly(db.sales)
        ..addColumns([count])
        ..where(
          db.sales.createdAt.isBiggerOrEqualValue(start) &
              db.sales.createdAt.isSmallerThanValue(
                start.add(const Duration(days: 1)),
              ),
        );
      final seq = ((await query.getSingle()).read(count) ?? 0) + 1;
      final sale = await db
          .into(db.sales)
          .insertReturning(
            SalesCompanion.insert(
              invoiceNo: formatInvoiceNo(
                prefix: invoicePrefix,
                date: at,
                seq: seq,
                deviceNo: deviceNo,
              ),
              branchId: Value(branch),
              staffId: Value(staffId),
              customerId: Value(customerId),
              subtotal: subtotal,
              discount: Value(billDiscount),
              vat: Value(vat),
              total: total,
              paid: total - due,
              due: Value(due),
              status: SaleStatus.finalized,
              createdAt: at,
            ),
          );
      for (final item in items) {
        await db
            .into(db.saleItems)
            .insert(
              SaleItemsCompanion.insert(
                saleId: sale.id,
                productId: Value(item.productId),
                nameSnapshot: item.nameSnapshot,
                qty: item.qty,
                unitPrice: item.unitPrice,
                lineDiscount: Value(item.lineDiscount),
                vatRateBp: Value(item.vatRateBp),
                lineTotal: item.lineTotal,
              ),
            );
        if (item.productId != null) {
          await db.stockDao.addMovement(
            productId: item.productId!,
            qtyDelta: -item.qty,
            type: MovementType.sale,
            refId: sale.id,
            branchId: branch,
            at: at,
          );
        }
      }
      for (final tender in tenders) {
        await db
            .into(db.salePayments)
            .insert(
              SalePaymentsCompanion.insert(
                saleId: sale.id,
                method: tender.method,
                amount: tender.amount,
                refNo: Value(tender.refNo),
              ),
            );
      }
      return sale;
    });
  }
}
