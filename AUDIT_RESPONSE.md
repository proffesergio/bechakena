# BechaKena 1.0.2 — response to audit #972

**Submission type:** offline Flutter retail/restaurant POS, with a static Next.js
marketing page and a browser-local demo. **Server/API endpoints shipped: zero.**
There is no Cloud Plan backend or Edge Function implementation in this release.
Cloud sync, remote owner access, SMS dispatch and activation services are future
work, not components omitted from an implemented backend.

## Requirement R5: authentication and roles

The audit marks server-side endpoint protection partial because it cannot find
HTTP endpoints. For this offline submission, that part of R5 is not applicable.
The applicable controls are PIN sign-in, the capability matrix, guarded routes,
live capability checks at local mutations, and branch-scoped record reads.
See `docs/SECURITY.md`, `lib/core/auth/rbac.dart`,
`lib/features/auth/logic/{permissions,access}.dart`, and their regression tests.
The local SQLite file and OS account remain trusted; this is not a hosted
multi-tenant service. A fresh audit/human review must determine the classification.

## Findings and disposition

| Finding | Source evidence / change |
| --- | --- |
| 2.1 Next.js prerelease | The exact dependency is `16.4.2`, a non-prerelease SemVer identifier, with an integrity-pinned lockfile; no canary/RC package is used. Retained the working version rather than downgrading to the suggested old 15.1.0 release. |
| 2.2–2.3 | Audit says no action required. Lockfiles retained. |
| 3.1 customer list | Already uses `scopedCustomersProvider` → `CustomersDao.watchAll(branchId:)`. Regression tests cover local, remote and shared customers. The cited unfiltered UI call is absent. |
| 3.2 product list | Products/categories are a shared catalog **within one module database**, not branch-owned records. `Products` has no `branch_id` or `watchAll()` method. Retail and restaurant each have a separate database; catalog queries also filter `businessType`. Stock quantities and transactions are branch-owned. Hiding a shared product based on stock would break new-outlet setup and zero-stock replenishment. |
| 3.3 inventory | Stock/alert providers now return zero/empty while the active outlet loads, instead of passing null and aggregating all outlets. Actual stock SQL already accepts a branch filter. |
| 3.4 sale detail | Added SQL branch predicates to `byId`, invoice lookup, sale items and payments; updated all UI item-read callers. A known ID cannot bypass a supplied branch scope. Report aggregates/refunds now use the same role scope. Owner null scope is explicit; empty scope denies reads. |
| Additional read hardening | Running-order lists filter the current outlet and retained order-editor screens recheck branch ownership. |
| 3.5 PIN hash | No change required, but the report's Argon2id/`pin_async_*` description is incorrect. Actual code is PBKDF2-HMAC-SHA256, 600,000 iterations, random salt, legacy upgrade and lockout. See `lib/core/auth/pin.dart` and PIN tests. |
| 4.1 indexes | All 25 real FKs already have a leftmost index prefix, including composite `(branch_id, created_at)` and `(branch_id, product_id)`. New exhaustive SQL tests verify coverage. Child `sale_id`, `purchase_id`, `order_id`, `return_id` indexes already exist. |
| 4.2 delete rules | All 25 FKs now explicitly use **ON DELETE RESTRICT**, both in Drift and shipped SQL. No cascading removal of immutable sales/stock history. Schema v9 upgrades rebuild FK tables atomically, preserve rows/indexes and check integrity before commit. Added a genuine v8 fixture and seeded upgrade test. Normal deletion remains soft deletion. The seed generator/script now restore FK enforcement after importing data. |
| 4.3 staff branch | `Staff` is module-wide and has no `branch_id`; branches are rows in `shops`, not a `branches` table. Adding an index on a nonexistent column is invalid. Branch selection is owner-only. |
| 4.4 stock index | Existing `(branch_id, product_id)` covers the equality lookup on both columns regardless of WHERE-clause order. `EXPLAIN QUERY PLAN` regression test confirms it is used. No duplicate reversed index was added. |
| 4.5–4.7 | Audit confirms safe scoped writes and runtime FK enforcement; retained. |
| 5.1–5.2 POS/order screens | Already coordinators using `app/widgets/product_picker.dart`, cart/order panes and checkout/settle dialogs; the reported 500+/450+ line monoliths are absent. |
| 5.3 duplicate manual item | Replaced both feature copies with `app/widgets/manual_item_dialog.dart`. Features supply save callbacks; validation, disposal, permissions, async failure handling and double-submit prevention stay in the shared form. Added a widget regression test. |
| 5.4 RBAC | Already an enum plus `Map<StaffRole, Set<Capability>>` in `core/auth/rbac.dart`; no role-string switch. |
| 5.5 printer configuration | Existing `PrinterConfig` in `printer_transport.dart` centralizes transport, port, receipt width and dots. ESC/POS byte generation remains separate from transport. |
| 5.6 generic base DAO | DAOs already extend Drift's typed `DatabaseAccessor`. Their domain queries and soft-delete rules differ. A second generic CRUD base would hide scope/immutability rules; retained typed domain DAOs. |
| 5.7 reports | Already delegates to six chart/stat widgets; the reported monolithic chart screen is absent. |
| 5.8 receipt | Already a small text formatter; `receipt_data.dart`, `escpos.dart`, rasterization and transport are separate. No new layout framework needed. |
| 5.9 migrations | Moved schema upgrades into `core/db/migrations.dart`; Drift already lazily exposes generated DAO getters, so no extra DAO factory was added. |
| 5.10 replenishment | Existing pure calculation is about 36 lines, not a 250-line function. Demand/lead/threshold arithmetic is covered by existing edge-case tests. |
| 5.11 settings | Extracted staff/branch settings and staff dialog to `settings/ui/widgets/`. Currency/tax validation and atomic persistence already live in `BusinessSettingsStore`. Kept printer/file operations in their existing services. |
| 5.12 cart | Already uses pure `core/pricing/pricing.dart`; cart state is about 111 lines. No duplicate pricing engine/discount class added. |
| 5.13 permissions | Already one generic `canProvider(Capability)` over the enum/map; the named per-action helper functions do not exist. |
| 5.14 router | Small capability-guarded router retained; splitting into per-feature route registries would add indirection without reducing a large file. |
| 5.15 converters | Two short converters already extend Drift `TypeConverter`. No Currency converter exists. A second generic converter base would duplicate Drift. |
| 5.16 checkout | Shared split-tender fields extracted to `app/widgets/tender_fields.dart`, used by both checkout flows. Receipt preview was already in `receipt_dialog.dart`. |
| 5.17 seed data | `demo_catalog.dart` contains typed catalog data, not customer/supplier fixtures. `tool/dump_seed.dart` already writes structured `database/seed.sql`. Retained the single typed catalog rather than duplicating it into new formats. |
| 6.1–6.3 Node/test gates | Setup and package engines require Node 22.18+ (22.x) or 24.x. Setup explicitly runs Flutter analyze/tests and npm tests before builds. |
| 6.4 Docker | Node image pinned to `22.23.3-alpine`; container build includes test inputs and runs tests before generating artifacts. |

## Checks and submission files

Run `flutter pub get`, localization/code generation, `flutter analyze`, and
`flutter test` with Flutter 3.47.7. `dart run tool/dump_schema.dart` regenerates
schema v9. From `site/`, run `npm ci`, `npm test`, `npm run build`, and
`npm run typecheck`. From the root, run:

```sh
python -m unittest discover -s scripts -p 'test*.py'
python scripts/make_submission_zip.py
```

Upload `dist/bechakena-vibe96.zip` and retain its SHA-256 companion. The archive
contains this response, schema/seed, tests and all current source; private env
files, credentials, generated Dart files and compiled/cache output are excluded.
Vercel Analytics is now included in the marketing layout; it does not add a
backend API or transmit local POS transaction records.

This response documents source facts and fixes. It does not claim Vibe96 has
cleared warnings or guarantee a specific score.
