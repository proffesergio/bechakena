# BechaKena 1.0.3 — response to audit #1051

Audit run #1051 stopped at the requirement list (0/100) because one must-have
was missing (R5) and two more were partial (R1, R3); R6 was partial, so the six
quality checks did not run. This release fixes those items and attaches the
requested evidence.

**Submission type:** offline Flutter retail/restaurant POS, with a static Next.js
marketing page and a browser-local demo.

**Runnable components in the archive: two.** (1) the Flutter POS and (2) the
Next.js static showcase. **Server/API endpoints shipped: zero.** There is no
separate admin application, no backend, no Edge Function and no hosted database
source. Back-office screens (staff, products, purchases, reports, settings) are
role-gated parts of the Flutter app. Cloud sync, remote owner access, SMS
dispatch and activation services are roadmap-only; they are not components
omitted from an implemented backend.

## R1 — complete source for every component

The source map is in `README.md#source-map--every-component` and
`docs/VIBE96.md#components--complete-source-no-hidden-adminapi`.

| Component | Source in the ZIP | Proof |
|---|---|---|
| Flutter POS | `lib/`, `test/`, `assets/`, `android/`, `ios/`, `linux/`, `windows/`, `web/`, `pubspec.yaml`, `pubspec.lock` | All Dart plus every platform runner. Windows ships the full C++ runner (`main.cpp`, `flutter_window.cpp/.h`, `win32_window.cpp/.h`, `utils.cpp/.h`, `Runner.rc`, `resource.h`, `runner.exe.manifest`, `runner/CMakeLists.txt`, `resources/app_icon.ico`) — not only CMake files. |
| Showcase | `site/` | Next.js static export; `app/` has only page/layout/robots/sitemap + CSS, no route handlers. |
| Database | `database/` | `schema.sql` (v9, 21 tables), `seed.sql`, generation notes. |
| Build/package/deploy | `scripts/`, `tool/`, `docker/`, `.github/`, `docker-compose.yml` | ZIP packager, schema/seed dumpers, Docker/nginx, CI/release workflows. |
| Mobile notes | `mobile/README.md` | Points at the single Flutter project at the root; source is not duplicated. |

**No separate admin app or API component exists.** The archive includes the
whole source tree above; nothing is shipped as a compiled-only part.

## R3 — builds from a clean machine

`HowToSetup.md` now starts with **Clean-machine quickstart (copy/paste)**. Exact
sequence:

```bash
flutter --version                 # 3.47.7 and its bundled Dart SDK
flutter pub get                   # restore from the committed lockfile
flutter gen-l10n
dart run build_runner build
sqlite3 review.db < database/schema.sql
sqlite3 review.db < database/seed.sql
sqlite3 review.db "PRAGMA user_version; PRAGMA integrity_check;"   # 9, ok
flutter run -d windows            # or flutter build windows --release
flutter analyze
flutter test
```

The SQL import was executed for this submission with Python's `sqlite3` module:
`user_version` = 9, `integrity_check` = ok, 21 tables, 0 FK violations, with the
seed rows loaded. The quickstart also gives the Windows app-support path
(`%APPDATA%\com.newell\bechakena\bechakena_superShop.db`) for a pre-seeded demo,
and the Android/iOS notes. The packager (`scripts/make_submission_zip.py`)
excludes `build/`, `.dart_tool/`, `node_modules/`, `site/.next/`, `site/out/`,
`.vercel/`, `dist/`, local databases, private env files and generated
`*.g.dart`/`*.freezed.dart`; the archive tests fail if any of those slip in.

## R5 — authentication and roles on every mutating endpoint

**This submission has no networked mutating endpoint.** There is no HTTP API,
no Next.js route handler, no Edge Function, no Supabase migration and no
separate admin/API component. The two runnable parts write as follows:

| Part | Transport | Writes |
|---|---|---|
| Flutter POS | No inbound endpoint; local process; optional outbound RAW/JetDirect TCP to a configured LAN printer | Local SQLite via Drift only |
| Next.js showcase | Static export files | None; browser demo uses IndexedDB |

The LAN printer path is outbound only (`Socket.connect` in
`lib/core/platform/lan_print_io.dart`) and sends ESC/POS receipt bytes, not
database rows. There is no `ServerSocket`, `HttpServer`, HTTP client or API
route. Because no endpoint accepts a write, there is no server-side endpoint to
authenticate. The applicable controls are the local PIN sign-in
(`lib/core/auth/pin.dart`), capability matrix (`lib/core/auth/rbac.dart`),
guarded routes, live checks at every local mutation
(`lib/features/auth/logic/permissions.dart`) and branch-scoped reads
(`lib/features/auth/logic/access.dart`). These are covered by
`test/features/auth/permissions_test.dart`, `access_test.dart` and the DB scoping
tests.

**Client-side RBAC is not a network security boundary.** It restricts local
user actions on the trusted device; it does not protect a hosted service, and
this submission does not claim otherwise. The OS account and physical device are
the trusted boundary, as documented in `docs/SECURITY.md`. A future Cloud Plan
would add a server that must enforce its own authentication and per-device
authorisation; that server code does not exist here.

Verification:

```bash
find site/app -type f
rg -n 'export async function (GET|POST|PUT|PATCH|DELETE)|NextResponse' site/app
# no matches
```

## R6 — pinned dependencies and CVE evidence

- `npm audit` (site): **0 vulnerabilities** — 64 dependencies (20 prod, 6 dev,
  39 optional).
- `flutter pub outdated`: retained as a version inventory, not CVE evidence.
- OSV.dev `Pub` scan of all **126 hosted** packages in `pubspec.lock`:
  **0 advisories** on 2026-10-27. Five SDK packages are excluded from the hosted
  package scan. `python scripts/audit_pub.py` reproduces the scan and records
  the lockfile SHA-256 and raw API results.
- Evidence is attached in `docs/dependency-audit/` and summarized in
  `docs/SECURITY.md#dependency-audit`. Both `site/package-lock.json` and
  `pubspec.lock` are committed; the tested versions remain pinned.

## Secret-scan note

The two candidate lines in `docs/BUILD.md` were documentation placeholders, not
credentials. They now read `storePassword=REDACTED` and `keyPassword=REDACTED`
with an instruction to fill them locally or from CI secrets in the git-ignored
`android/key.properties`. No live key material was present in the repository or
archive; `.env.example` contains placeholders only.

## Prior audit #972 — findings and disposition

| Finding | Source evidence / change |
| --- | --- |
| 2.1 Next.js prerelease | The exact dependency is `16.4.2`, an official non-prerelease release with an integrity-pinned lockfile; see [upstream release](https://github.com/vercel/next.js/releases/tag/v16.4.2). No canary/RC package is used. Fresh npm audit reports zero advisories. |
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

### Verification on 2026-10-27

- Restored dependencies with `flutter pub get --enforce-lockfile` using an
  isolated Flutter 3.47.7 SDK (Dart 3.13.5), then regenerated localization and
  Drift sources. `flutter analyze` reports no issues; all **224 Flutter tests
  pass**, including branch access, schema/seed, v8 migration and shared forms.
  Regeneration also refreshed the checked-in Drift file's 25 FK constraints
  to match the explicit `ON DELETE RESTRICT` rules in the table definitions.
- All **5 site tests pass**; production static export and TypeScript checks pass.
- The Flutter release web build passes with `/demo/` as its base path and
  bundled web resources. All **14 Python tests pass**, with no skips; static
  site/demo validation confirms the expected assets, WASM signatures and paths.
- Fresh npm and hosted Pub advisory scans report zero advisories; the Pub scan
  now records raw API results and lockfile hashes, with the corrected package
  count explained above.
- Fixed the PowerShell SQL import, contradictory cloud setup claims, missing
  Docker test context and obsolete code-generator flags. The source packager
  now requires Windows headers/CMake files and other platform build inputs,
  rejects linked source directories and excludes SQLite sidecars/local keys.
- Docker runtime validation is unavailable because Docker Desktop's Linux
  daemon is not running. No native Windows/Android/iOS release build is claimed
  by this verification run.

Run `flutter pub get`, localization/code generation, `flutter analyze`, and
`flutter test` with Flutter 3.47.7. `dart run tool/dump_schema.dart` regenerates
schema v9. From `site/`, run `npm ci`, `npm test`, `npm run build`, and
`npm run typecheck`. From the root, run:

```sh
python -m unittest discover -s scripts -p 'test*.py'
python scripts/make_submission_zip.py
```

Upload `dist/bechakena-vibe96.zip` and retain its SHA-256 companion. The archive
contains this response, the full Flutter/platform source (including the Windows
C++ runner), the static `site/`, schema/seed, tests and the
`docs/dependency-audit/` evidence; private env files, credentials, generated
Dart files and compiled/cache output are excluded. Vercel Analytics is included
in the marketing layout; it does not add a backend API or transmit local POS
transaction records.

This response documents source facts and fixes. It does not claim Vibe96 has
cleared warnings or guarantee a specific score.
