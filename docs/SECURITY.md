# Security model

BechaKena runs in the shop, on hardware the owner controls, with no required
network. This note documents how it protects access to data, what the audit
surface is, and what is deliberately out of scope.

## Threat model

The realistic risks for a shop POS are **counter-level**, not internet-scale:

- someone at the counter reading another outlet's sales/customer baki;
- a cashier performing owner-level actions (refunds, staff changes, price edits);
- tampering with the local database file on disk.

The app assumes the OS account and the physical device are trusted (standard
for a single-shop install); it hardens everything above that line.

## Authentication

- **Staff sign-in:** numeric PIN, minimum 4 digits, verified against a stored
  hash — never plaintext.
- **PIN hashing:** PBKDF2-HMAC-SHA256 with a per-credential 16-byte random
  salt and **600,000 iterations** (`lib/core/auth/pin.dart`). Stored format is
  `pbkdf2sha256$<iterations>$<salt>$<digest>`, so iteration counts can be
  raised without invalidating existing PINs. Successful sign-in upgrades older hashes. Five failed attempts lock that staff account for 30 seconds; native hashing runs in a background isolate.
- **Roles:** `owner` / `manager` / `cashier` via a capability matrix
  (`lib/core/auth/rbac.dart`, exposed through provider wrappers in `lib/features/auth/logic/permissions.dart`). Unknown roles fail closed.

## Authorisation — local-only, no networked mutating endpoints (R5)

**R5 statement: this submission ships zero networked mutating endpoints.** There
is no HTTP API, no Next.js route handler, no Edge Function, no Supabase migration
and no separate admin/API component in the archive. The two runnable parts are:

| Part | Transport | Where writes go |
|---|---|---|
| Flutter POS (`lib/`, `android/`, `ios/`, `windows/`, `linux/`, `web/`) | no inbound endpoint; local process (optional outbound RAW/JetDirect TCP to a configured LAN printer) | local SQLite through Drift only |
| Next.js showcase (`site/`) | static export files only (`output: "export"`) | none; the browser demo keeps visitor data in the browser's IndexedDB |

The LAN printer path is outbound only (`Socket.connect` in
`lib/core/platform/lan_print_io.dart`); it accepts no connection and sends only
ESC/POS receipt bytes, not database rows. There is no `ServerSocket`,
`HttpServer`, HTTP client or API route in the app or showcase.

Because no endpoint accepts a write, server-side endpoint authentication is not
an applicable component of this offline release. The applicable controls are the
local PIN sign-in, capability matrix, guarded routes, live capability checks at
local mutations, and branch-scoped reads described below.

**Client-side RBAC is not a network security boundary.** It stops a signed-in
cashier from using owner/manager actions on this device; it does not protect a
hosted service, because no hosted service exists. The OS account and physical
device are trusted. A future Cloud Plan would introduce a server, and that
server would have to enforce its own authentication and per-device authorisation;
no such backend code ships here.

Reviewer verification (from the repository root):

```bash
find site/app -type f        # page/layout/robots/sitemap + CSS only
rg -n 'export async function (GET|POST|PUT|PATCH|DELETE)|NextResponse' site/app
# no matches
```

- **Capability checks** gate every mutating action (returns, price edits,
  purchases, staff management, settings) through
  `permissions.dart` at the UI/logic boundary.
- **Branch scoping on reads** (`lib/features/auth/logic/access.dart`): every
  branch-attributed read — sales history, purchases, customer lists, POS
  customer pickers — is filtered to the session's branch for non-owner roles.
  Detail dialogs re-verify the record's branch (`canViewBranch`) before
  rendering, so navigating at a record id alone cannot expose another outlet's
  data. Owners run the head-office view across branches.
- The scope is applied in SQL (DAOs take an optional `branchId`), not just in
  the widget tree, and callers must pass the current scope. DAOs are trusted local persistence APIs; they do not independently authenticate callers.
- Sale ID/invoice lookups, child items/payments and report aggregates accept the
  same branch scope in SQL. Stock/alert providers fail closed while the outlet
  loads. Running-order lists use the active outlet.
- Product/category catalogs and staff accounts are shared across branches of
  one module. They have no branch ownership column; stock and transactions do.
  The retail and restaurant modules use separate database files.

## Data integrity

- **Finalized sales are immutable.** Corrections go through returns and stock
  adjustments, both append-only and auditable.
- **Stock is derived** (`SUM(stock_movements.qty_delta)` per branch/product),
  never a stored counter that could drift.
- All 25 FKs have an index prefix and explicit `ON DELETE RESTRICT`; physical
  deletion cannot cascade through financial history. Schema v9 upgrades run
  atomically, preserve records and validate FKs before commit.
- Every synced row carries `id`, `updatedAt`, `deletedAt`, `deviceId`; deletes
  are soft, so sync conflicts resolve deterministically (last-writer-wins on
  `updatedAt`).

## Secrets

- No credentials ship in the repository or the app. `.env.example` contains
  placeholders only.
- Build-time `--dart-define` values (`lib/app/config.dart`) are **public
  identifiers** (API URL, Supabase anon key, license *public* key) that are
  compiled into the binary by design.
- Server-side secrets (`SUPABASE_SERVICE_ROLE_KEY`, `SMS_API_KEY`, license
  private key, Vercel tokens) live only in the server/CI environment.
- A future Cloud Plan would need to issue per-device tokens at runtime and
  store them securely. No such backend/token issuance ships in this release.

## Cloud backend scope

The optional Supabase Cloud Plan is additive and off by default; the app is
complete and offline without it. No working backend or Edge Functions are supplied: **only the client contract and roadmap ship**. Sync and SMS dispatch remain unimplemented server work. A deployment of the backend is expected to enforce its own authz
(service-role isolation, per-device tokens) — that layer never weakens the
offline behaviour documented here.

## Dependency audit

Evidence for R6. npm and OSV scans were rerun on **2026-10-27 (UTC)** against
the submission lockfiles. The version inventory is retained from October 26.
Raw output is attached under [`dependency-audit/`](dependency-audit/).

### Node / Next.js showcase (`site/`)

```bash
cd site && npm audit --json
```

**Result: 0 vulnerabilities** — 0 critical, 0 high, 0 moderate, 0 low, 0 info
across 64 dependencies (20 prod, 6 dev, 39 optional). `site/package-lock.json`
is committed and integrity-pinned. Raw output:
[`dependency-audit/npm-audit.json`](dependency-audit/npm-audit.json).

### Dart / Flutter (`pubspec.lock`)

```bash
flutter pub outdated --no-color
```

Direct dependencies at capture time (full transitive output in
[`dependency-audit/pub-outdated.txt`](dependency-audit/pub-outdated.txt)):

| Package | Current (locked/tested) | Latest available | Security note |
|---|---:|---:|---|
| `crypto` | 3.0.7 | 3.0.8 | no advisory |
| `cupertino_icons` | 1.0.9 | 2.0.0 | no advisory; major upgrade not required |
| `drift` | 2.35.2 | 2.35.3 | no advisory |
| `fl_chart` | 1.2.0 | 1.3.0 | no advisory |
| `go_router` | 17.5.0 | 18.1.1 | no advisory; major upgrade not required |
| `web` | 1.1.1 | 1.1.2 | no advisory |
| `build_runner` (dev) | 2.16.2 | 2.17.1 | no advisory |
| `drift_dev` (dev) | 2.35.1 | 2.35.2 | no advisory |
| `sqlite3` (dev) | 3.7.1 | 3.8.0 | no advisory |

Newer releases exist for maintenance, but `pubspec.lock` pins the versions that
were built and tested for this submission.

### Vulnerability scan for the Dart lockfile

Dart has no built-in `pub audit`, so every hosted package/version pair in
`pubspec.lock` (126 packages) was checked against the OSV.dev advisory database
for the `Pub` ecosystem. Five packages with `source: sdk` belong to the Flutter
SDK and are excluded; the older count of 131 incorrectly included them.

```bash
python scripts/audit_pub.py
# Result: 126 hosted packages, 0 advisories
```

**Result: 0 known advisories** for the exact locked versions. Structured scan
result (UTC timestamp, lockfile SHA-256, every package/version, raw responses and hits):
[`dependency-audit/osv-pub-scan.json`](dependency-audit/osv-pub-scan.json).

**Conclusion:** both dependency sets are pinned with committed lockfiles, and no
known advisory was returned for the audited npm and hosted Pub dependencies on
2026-10-27. This does not cover the Flutter SDK, native toolchains, or unknown
vulnerabilities. `flutter pub outdated` is a version inventory, not a CVE scan.

## Reporting

Found an issue? Open an issue in the repository (no security-sensitive data in
the report) or contact the address in the repository profile.
