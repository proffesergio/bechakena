/// Regenerates `database/seed.sql` — the demo dataset reviewers and buyers use
/// to see a working system without typing anything in.
///
///     dart run tool/dump_seed.dart
///
/// The data is produced through the app's real DAOs (sale finalization,
/// purchases, demo catalog), then dumped as portable INSERT statements, so the
/// file can never disagree with the engines that create it. Uses only demo
/// products/prices and a demo owner PIN — no real customer data.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:bechakena/core/auth/pin.dart' show verifyPin;
import 'package:bechakena/core/db/database.dart';
import 'package:bechakena/core/db/sale_draft.dart';
import 'package:bechakena/core/money.dart';
import 'package:bechakena/core/qty.dart';
import 'package:bechakena/core/seed/demo_catalog.dart';

/// Tables in foreign-key-safe order. Sync plumbing (sync_outbox) and empty
/// tables (returns, sms_log, dine_orders) are intentionally omitted.
const _tables = <(String, String)>[
  ('shops', 'Shop profile (single branch in the demo)'),
  ('settings', 'Device settings — pins the current branch'),
  ('staff', 'Owner account — demo PIN is 1234'),
  ('dining_tables', 'Restaurant floor plan'),
  ('categories', 'Retail + restaurant categories'),
  ('products', 'Demo catalog (retail + restaurant menus)'),
  ('customers', 'Baki khata customers'),
  ('suppliers', 'Demo supplier'),
  ('purchases', 'A restocking purchase'),
  ('purchase_items', 'Purchase lines'),
  ('sales', 'Finalized demo sales'),
  ('sale_items', 'Sale lines'),
  ('sale_payments', 'Cash / bKash tenders'),
  ('due_payments', 'A baki repayment'),
  ('stock_movements', 'Derived stock history — stock = SUM(qty_delta)'),
];

Future<void> main() async {
  final db = AppDatabase(NativeDatabase.memory());
  try {
    // Force the open so the branch bootstrap has run before we seed.
    await db.customStatement('SELECT 1');
    final branchId = (await db.currentBranchId())!;
    final now = DateTime.now().toUtc();

    await _seedShop(db, branchId);
    final owner = await _seedOwner(db);
    await _seedDiningTables(db);
    await seedDemoData(db, businessType: 'superShop');
    await seedDemoData(db, businessType: 'restaurant');
    final supplier = await _seedPurchase(db, branchId, now);
    await _seedSales(db, branchId, owner.id, now);
    await _seedDuePayment(db, owner.id);

    final buffer = StringBuffer(_header)
      ..writeln('-- Generated: ${now.toIso8601String()}')
      ..writeln('-- Demo owner PIN: 1234')
      ..writeln()
      ..writeln('PRAGMA foreign_keys = OFF;')
      ..writeln('BEGIN TRANSACTION;');
    for (final (table, comment) in _tables) {
      final rows = await db.customSelect('SELECT * FROM "$table"').get();
      buffer
        ..writeln()
        ..writeln('-- $comment (${rows.length} row${rows.length == 1 ? '' : 's'})');
      if (rows.isEmpty) {
        buffer.writeln('-- (none)');
        continue;
      }
      final columns = rows.first.data.keys.toList();
      final columnList = columns.map((c) => '"$c"').join(', ');
      for (final row in rows) {
        final values =
            columns.map((c) => _literal(row.data[c])).join(', ');
        buffer.writeln(
            'INSERT OR REPLACE INTO "$table" ($columnList) VALUES ($values);');
      }
    }
    buffer
      ..writeln()
      ..writeln('COMMIT;')
      ..writeln('PRAGMA foreign_keys = ON;');

    final out = File('database/seed.sql');
    out.parent.createSync(recursive: true);
    out.writeAsStringSync(buffer.toString());
    stdout.writeln('Wrote ${out.path} '
        '(supplier ${supplier.id.substring(0, 8)}…, owner ${owner.id.substring(0, 8)}…).');
  } finally {
    await db.close();
  }
}

Future<void> _seedShop(AppDatabase db, String branchId) {
  return (db.update(db.shops)..where((s) => s.id.equals(branchId))).write(
    ShopsCompanion(
      name: const Value('BechaKena Demo Shop'),
      nameBn: const Value('বেচাকেনা ডেমো শপ'),
      address: const Value('12 Mirpur Road, Dhanmondi, Dhaka 1205'),
      phone: const Value('01711-000000'),
      receiptFooter: const Value('ধন্যবাদ! Thank you — come again.'),
      invoicePrefix: const Value('BK'),
    ),
  );
}

Future<StaffData> _seedOwner(AppDatabase db) {
  // Fixed salt so repeated generations byte-match; the hash is the app's own
  // PBKDF2-HMAC-SHA256 format, verified with the app's verifyPin below.
  final salt = utf8.encode('bechakena-seed');
  const pin = '1234';
  final hmac = Hmac(sha256, utf8.encode(pin));
  var u = Uint8List.fromList(hmac.convert([...salt, 0, 0, 0, 1]).bytes);
  final digest = Uint8List.fromList(u);
  for (var i = 1; i < 12000; i++) {
    u = Uint8List.fromList(hmac.convert(u).bytes);
    for (var j = 0; j < digest.length; j++) {
      digest[j] ^= u[j];
    }
  }
  final hash =
      'pbkdf2sha256\$12000\$${base64.encode(salt)}\$${base64.encode(digest)}';
  if (!verifyPin(pin, hash)) {
    throw StateError('Generated PIN hash does not verify');
  }
  return db.staffDao
      .createStaff(name: 'Demo Owner', pin: pin, role: StaffRole.owner);
}

Future<void> _seedDiningTables(AppDatabase db) async {
  const tables = [
    ('Table 1', 'Main Hall', 4, 0),
    ('Table 2', 'Main Hall', 4, 1),
    ('Table 3', 'Main Hall', 2, 2),
    ('Table 4', 'Rooftop', 6, 3),
    ('Table 5', 'Rooftop', 6, 4),
    ('Takeaway counter', 'Main Hall', 0, 5),
  ];
  for (final (name, area, seats, order) in tables) {
    await db.into(db.diningTables).insert(DiningTablesCompanion.insert(
          name: name,
          area: Value(area),
          seats: Value(seats),
          sortOrder: Value(order),
        ));
  }
}

Future<Supplier> _seedPurchase(
    AppDatabase db, String branchId, DateTime now) async {
  final supplier = await db.purchasesDao.insertSupplier(
      SuppliersCompanion.insert(
          name: 'Fresh Foods Ltd.',
          phone: const Value('01911-222333'),
          address: const Value('Karwan Bazar, Dhaka')));

  final rice = await _productByName(db, 'Miniket Rice 5kg');
  final oil = await _productByName(db, 'Rupchanda Soybean Oil 5L');
  final milk = await _productByName(db, 'Milk Vita UHT Milk 1L');

  await db.purchasesDao.createPurchase(
    supplierId: supplier.id,
    invoiceRef: 'FF-2026-0042',
    branchId: branchId,
    now: now.subtract(const Duration(days: 4)),
    items: [
      PurchaseDraftItem(
          productId: rice.id,
          qty: Qty.fromCount(24),
          unitCost: const Money(44000)),
      PurchaseDraftItem(
          productId: oil.id,
          qty: Qty.fromCount(12),
          unitCost: const Money(81000)),
      PurchaseDraftItem(
          productId: milk.id,
          qty: Qty.fromCount(36),
          unitCost: const Money(10200),
          expiryDate: now.add(const Duration(days: 12))),
    ],
  );
  return supplier;
}

Future<void> _seedSales(
    AppDatabase db, String branchId, String staffId, DateTime now) async {
  final rice = await _productByName(db, 'Miniket Rice 5kg');
  final oil = await _productByName(db, 'Rupchanda Soybean Oil 5L');
  final dal = await _productByName(db, 'Masoor Dal');
  final customers = await db.select(db.customers).get();
  final karim = customers.firstWhere((c) => c.name == 'করিম মিয়া');

  SaleDraftItem line(Product p, int qty) => SaleDraftItem(
        productId: p.id,
        nameSnapshot: p.name,
        qty: Qty.fromCount(qty),
        unitPrice: p.salePrice,
        vatRateBp: p.vatRateBp,
      );

  // Two days ago — plain cash sale.
  await db.salesDao.finalizeSale(
    invoicePrefix: 'BK',
    branchId: branchId,
    staffId: staffId,
    items: [line(rice, 1), line(dal, 2)],
    tenders: [TenderDraft(method: PayMethod.cash, amount: const Money(85000))],
    now: now.subtract(const Duration(days: 2, hours: 3)),
  );

  // Yesterday — bKash payment.
  await db.salesDao.finalizeSale(
    invoicePrefix: 'BK',
    branchId: branchId,
    staffId: staffId,
    items: [line(oil, 1)],
    tenders: [
      TenderDraft(
          method: PayMethod.bkash,
          amount: const Money(87500),
          refNo: 'BKS7H2K91'),
    ],
    now: now.subtract(const Duration(days: 1, hours: 5)),
  );

  // Today — partial cash, the rest books as baki on করিম মিয়া.
  await db.salesDao.finalizeSale(
    invoicePrefix: 'BK',
    branchId: branchId,
    staffId: staffId,
    customerId: karim.id,
    items: [line(rice, 2)],
    tenders: [TenderDraft(method: PayMethod.cash, amount: const Money(50000))],
    now: now.subtract(const Duration(hours: 2)),
  );
}

Future<void> _seedDuePayment(AppDatabase db, String staffId) async {
  final customers = await db.select(db.customers).get();
  final karim = customers.firstWhere((c) => c.name == 'করিম মিয়া');
  await db.customersDao.addDuePayment(
    customerId: karim.id,
    amount: const Money(20000),
    method: PayMethod.cash,
  );
}

Future<Product> _productByName(AppDatabase db, String name) async {
  final row = await (db.select(db.products)..where((p) => p.name.equals(name)))
      .getSingle();
  return row;
}

String _literal(Object? value) {
  if (value == null) return 'NULL';
  if (value is bool) return value ? '1' : '0';
  if (value is int) return '$value';
  if (value is double) return value.toString();
  if (value is Uint8List) {
    return "X'${value.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}'";
  }
  return "'${value.toString().replaceAll("'", "''")}'";
}

const _header = '''-- ─────────────────────────────────────────────────────────────────────────────
-- BechaKena — demo seed data for database/schema.sql.
--
-- What you get: a shop profile, one branch, an owner login (PIN 1234), the
-- full demo catalog for both retail and restaurant, two baki-khata customers,
-- a supplier purchase with expiry dates, three finalized sales (cash, bKash,
-- and a partial-payment/baki sale) and their stock movements. Reports, the
-- dashboard and inventory alerts all have real history to show.
--
-- Apply to a fresh database:
--
--     sqlite3 bechakena_superShop.db < database/schema.sql
--     sqlite3 bechakena_superShop.db < database/seed.sql
--
-- Then launch the app and sign in as "Demo Owner" with PIN 1234.
--
-- Regenerate with: dart run tool/dump_seed.dart
--
-- DEMO DATA ONLY. Change the owner PIN (Settings → Staff & PINs) before any
-- real use; never load this into a production shop's database.
-- ─────────────────────────────────────────────────────────────────────────────
''';
