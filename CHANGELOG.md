# Changelog

All notable changes to BechaKena are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/). Releases are cut by pushing a
`v*` tag; CI attaches the Windows build and Android APK to the GitHub Release.

## [1.0.0] — 2026-10-19

The first complete, offline-first release: retail POS and restaurant service
in one app, Bangla + English throughout, with an optional Cloud Plan.

### Added

- **Point of sale (retail)** — animated product grid with live search by
  Bangla name, English name or barcode; USB barcode-scanner (keyboard-wedge)
  support; fractional quantities for loose goods with exact milli-unit math;
  per-line and whole-bill discounts; VAT-inclusive pricing; split tender
  across cash / bKash / Nagad / card with automatic change calculation.
- **Restaurant service** — dining-table floor with live tabs; dine-in,
  takeaway and delivery orders; running tabs that survive restarts; kitchen
  tickets (KOT) printing only newly added items; settle converts the tab into
  an immutable sale through the same engine as retail.
- **Baki khata (customer credit)** — sales attach to customers, shortfalls
  book as due automatically; running balances derived from immutable records;
  due payments in two taps; SMS due-reminder templates (bn/en) with a local
  outbox queue.
- **Inventory** — stock derived per product and branch from append-only
  movements; opening stock, purchase restocking with expiry dates,
  low-stock and expiring-soon alerts, signed stock adjustments with reasons.
- **Purchases & suppliers** — supplier records, purchase entries with per-line
  unit cost and optional expiry.
- **Returns & sales history** — refunds against finalized sales with stock
  restocking; browse and reprint past receipts.
- **Reports** — daily dashboard (transactions, sales, new dues), date-range
  sales trend, top products, payment-method split, VAT summary and
  sales-by-staff breakdown.
- **Staff, roles & branches** — offline PIN login; first-run owner setup;
  capability matrix with owner/manager/cashier roles; per-staff sales
  attribution; multi-branch stock, sales and orders.
- **Products** — categories, barcodes, units, pricing, low-stock levels,
  emoji or image art, CSV import/export.
- **Printing** — ESC/POS receipts (58/80 mm) and kitchen tickets over
  LAN/JetDirect, with USB and Bluetooth transports behind a plugin flag;
  shop-logo raster header; test print; `Tk` amount formatting for cheap
  thermal printers.
- **Backup & restore** — one-tap snapshots to the file system and deferred
  restore on next launch; per-module factory reset.
- **Localization** — every string in Bangla and English (252 ARB keys), ৳ and
  lakh-style number formatting, bundled Noto Sans Bengali font.
- **Showcase** — bilingual Next.js landing page plus a browser POS demo at
  `/demo/`, packaged for Vercel with a validated build pipeline, and a
  clean-machine Docker image that serves both.
- **Database scripts** — `database/schema.sql` (schema v6, 21 tables) and
  `database/seed.sql` (demo shop), generated from the app's Drift schema and
  DAOs and verified by tests.
- **Documentation** — [`HowToSetup.md`](HowToSetup.md),
  [`docs/DESIGN.md`](docs/DESIGN.md), [`docs/BUILD.md`](docs/BUILD.md),
  [`docs/OPERATIONS.md`](docs/OPERATIONS.md), [`.env.example`](.env.example).

### Security

- Finalized sales are immutable and money is integer paisa — rounding and
  tampering flaws are structurally impossible.
- Staff PINs are stored as salted, iterated PBKDF2-HMAC-SHA256 digests;
  verification is fully offline.
- The app requires no network and ships no credentials; server-side secrets
  live only in `.env`/CI secrets (see [`.env.example`](.env.example)).

### Known limitations

- Bangla bitmap text on the receipt body is still on the roadmap (receipts
  print Bangla via the printer's built-in font where supported; UI is full
  Bangla).
- The Cloud Plan (Supabase sync, SMS dispatch, Ed25519 licensing) is designed
  and scaffolded but not enabled by default in this release.

[1.0.0]: https://github.com/your-org/bechakena/releases/tag/v1.0.0
