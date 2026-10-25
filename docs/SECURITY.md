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

## Authorisation

**Submission R5 scope:** this release ships zero HTTP API endpoints. The Next.js
site is a static export and the POS database is local to the device/browser.
Server-side endpoint authentication is therefore not an applicable component
of this offline release. Local authentication and role controls below are the
auditable boundary; no Cloud Plan backend is implemented or deployed here.

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

## Reporting

Found an issue? Open an issue in the repository (no security-sensitive data in
the report) or contact the address in the repository profile.
