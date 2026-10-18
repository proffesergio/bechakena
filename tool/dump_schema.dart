/// Regenerates `database/schema.sql` from the Drift table definitions.
///
///     dart run tool/dump_schema.dart
///
/// Run this after editing `lib/core/db/tables.dart` so the SQL script that
/// reviewers, DBAs and backup tooling read stays identical to the schema the
/// app creates on first launch. The dump is taken from a real in-memory
/// database, so it is exactly what SQLite receives — no hand-written drift.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:bechakena/core/db/database.dart';

Future<void> main() async {
  final db = AppDatabase(NativeDatabase.memory());
  try {
    final rows = await db.customSelect(
      "SELECT type, name, sql FROM sqlite_master "
      "WHERE sql IS NOT NULL AND name NOT LIKE 'sqlite_%' "
      "ORDER BY CASE type WHEN 'table' THEN 0 WHEN 'index' THEN 1 ELSE 2 END, "
      "name",
    ).get();

    final buffer = StringBuffer(_header)
      ..writeln('-- Schema version: v${db.schemaVersion}')
      ..writeln('-- Generated:      dart run tool/dump_schema.dart')
      ..writeln('-- Tables:         ${_tableCount(rows)}');
    for (final row in rows) {
      var sql = row.read<String>('sql').trim();
      if (!sql.endsWith(';')) sql = '$sql;';
      buffer
        ..writeln()
        ..writeln(sql);
    }
    // Drift reads this pragma to decide whether migrations are needed: a
    // script-created database must present itself as the current version or
    // the app would try to create tables that already exist.
    buffer
      ..writeln()
      ..writeln('PRAGMA user_version = ${db.schemaVersion};');

    final out = File('database/schema.sql');
    out.parent.createSync(recursive: true);
    out.writeAsStringSync(buffer.toString());
    stdout.writeln('Wrote ${out.path} (${_tableCount(rows)} tables).');
  } finally {
    await db.close();
  }
}

int _tableCount(List<QueryRow> rows) =>
    rows.where((row) => row.read<String>('type') == 'table').length;

const _header = '''-- ─────────────────────────────────────────────────────────────────────────────
-- BechaKena — complete SQLite schema, schema version 6.
--
-- This file creates the database from scratch. It is generated from the Drift
-- table definitions in lib/core/db/tables.dart, which remain the source of
-- truth; upgrade migrations for older installs live in
-- lib/core/db/database.dart (MigrationStrategy).
--
-- How the app uses it:
--   • Each business module owns its own SQLite file — 'bechakena_superShop.db'
--     / 'bechakena_restaurant.db' in the app support directory — and creates
--     this schema on first launch. Nothing here needs to be run by hand.
--   • `dart run tool/dump_schema.dart` regenerates this file.
--
-- Conventions you can rely on:
--   • Money columns are INTEGER paisa (1 BDT = 100 paisa); never floats.
--   • Quantity columns are INTEGER milli-units (1 pc = 1000; 250 g = 250 kg).
--   • Stock is derived: stock = SUM(stock_movements.qty_delta) per product
--     and branch. There is no stored stock column anywhere.
--   • Finalized sales are immutable; corrections are returns/adjustments.
--   • Every synced row carries id (UUIDv7), updated_at, deleted_at and
--     device_id for the optional multi-device Cloud Plan.
--   • id/updated_at/device_id defaults are applied by the app, not by SQLite,
--     so this script always receives explicit values on insert.
-- ─────────────────────────────────────────────────────────────────────────────
''';
