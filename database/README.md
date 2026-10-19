# BechaKena — database scripts

These are the **shipped** database scripts for BechaKena. The app creates its
own SQLite database on first launch (Drift); these files exist so the schema is
reviewable, scriptable, and reproducible without running the app.

The optional Cloud Plan (server-side Supabase) is roadmap-only: there are no
server migrations or backend scripts in this archive. `schema.sql` is the
complete data model the app runs on, fully local.

| File | What it is |
|---|---|
| `schema.sql` | The complete schema, schema version 8 — 21 tables, foreign keys, unique + hot-path indexes, `PRAGMA user_version = 8` |
| `seed.sql` | Demo dataset: shop, owner (`Demo Owner` / PIN `1234`), branch, retail + restaurant catalogs, customers, suppliers, a purchase with expiry dates, three finalized sales (cash, bKash, baki) and the derived stock movements |

## Apply to a fresh database

```bash
sqlite3 bechakena_superShop.db < database/schema.sql
sqlite3 bechakena_superShop.db < database/seed.sql
```

The result opens in the app as a working shop. `PRAGMA user_version = 8` tells
the app migrations are already applied; without it the app would try to create
tables that exist. `seed.sql` is demo data — never load it into a real shop's
database, and change the demo PIN first if you keep the data.

## Regenerate (after changing `lib/core/db/tables.dart`)

```bash
dart run tool/dump_schema.dart    # rewrites database/schema.sql
dart run tool/dump_seed.dart      # rewrites database/seed.sql (fresh demo dates/UUIDs)
```

The dumps are taken from a real database opened through the app's own Drift
code — the seed is produced by the production DAOs (sale finalization,
purchases, demo catalog) — so the scripts cannot silently drift from the
engines that read them. `flutter test test/core/db/schema_seed_test.dart`
applies both scripts to a fresh SQLite file, runs `PRAGMA integrity_check`,
then opens the file with the app's `AppDatabase` and verifies login, derived
stock, dues and demo sales.

## Rules the schema encodes

- **Money is integer minor units (100 per configured currency).** `subtotal`, `total`, `qty` etc. are never
  floating point. Legacy BDT amounts use paisa; currency changes are locked once priced records exist.
- **Quantity is integer milli-units.** 1 pc = 1000, 250 g = 250.
- **Stock is derived, never stored:**
  `stock(product, branch) = SUM(stock_movements.qty_delta)`.
- **Finalized sales are immutable.** Corrections go through `returns` /
  `return_items` and stock adjustments.
- **Sync contract:** every synced row carries `id` (UUIDv7), `updated_at`,
  `deleted_at`, `device_id` for the optional multi-device Cloud Plan.
- **Two modules, two files.** `business_type` keeps the retail catalog and the
  restaurant menu separate; the app additionally runs each module in its own
  SQLite file (`bechakena_superShop.db`, `bechakena_restaurant.db`).

Upgrade migrations for installs created by older app versions are Dart code in
`lib/core/db/database.dart` (`MigrationStrategy`, v2→v8); a fresh install and
`schema.sql` always produce the same current shape.
