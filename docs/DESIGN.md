
# BechaKena — Design Document

**Product:** BechaKena (বেচাকেনা) — offline-first supermarket POS & inventory for Bangladesh
**Company:** neWell Software
**Platforms:** Windows desktop (primary), Android, iOS — one Flutter codebase
**Status:** v1 in development · Last updated: 2026-07-09

---

## 1. Product thesis

Local supershop owners in Bangladesh run on paper khata, TallyKhata, or pirated
legacy POS. BechaKena wins the sale in a 5-minute demo with:

1. **A branded bill** printed on their own thermal printer with their logo and
   phone number, in seconds.
2. **Baki khata built into the POS** — customer credit, due tracking, and SMS
   reminders, so the owner drops the paper ledger the same day.
3. **Inventory that maintains itself** — every sale decrements stock; purchases
   restock; low-stock and expiry alerts.
4. **Bangla-first, beautiful, fast** — full বাংলা/English toggle, ৳ formatting,
   animated product grid, works during load-shedding with zero internet.

**Business model:** one-time license per shop (no monthly-bill objection) +
optional **Cloud Plan** subscription: encrypted backup, multi-device sync,
owner's remote mobile app.

## 2. Tech stack

| Layer | Choice | Why |
|---|---|---|
| UI/app | Flutter 3.44 (Dart) | One codebase → Windows/Android/iOS; best animation tooling |
| State | Riverpod | Compile-safe DI + reactive state, testable |
| Routing | go_router | Declarative, deep-link ready |
| Local DB | Drift (SQLite) | Typed schema, reactive queries, offline source of truth |
| Cloud | Supabase (Postgres, Auth, Storage, Edge Functions) | Sync target, licensing, SMS dispatch |
| Printing | ESC/POS over USB/Bluetooth/Network (esc_pos family) | 58/80mm thermal, logo raster |
| Animations | flutter_animate + implicit animations | "Framer Motion" feel |
| l10n | Flutter ARB (`bn`, `en`) | Bangla-first |
| CI/CD | GitHub Actions | analyze + test on PR; tagged release builds Windows zip + Android APK |

**Offline-first rule:** the app must be 100% functional with no network,
forever. Cloud features are additive, never required. SQLite is the source of
truth on-device; Supabase is the sync/backup hub.

## 3. Architecture

```
┌────────────────────────── Flutter app ──────────────────────────┐
│  features/  pos · products · inventory · customers(baki) ·      │
│             purchases · reports · settings                      │
│  core/      db (Drift) · sync engine · printing · license ·     │
│             barcode listener · sms queue                        │
│  app/       router · theme · l10n · providers                   │
└───────────────┬─────────────────────────────────────────────────┘
                │ outbox push / cursor pull (when online + Cloud Plan)
┌───────────────▼───────────── Supabase ──────────────────────────┐
│  Postgres (mirror schema, RLS by shop_id) · Auth · Storage      │
│  Edge functions: activate-license · send-sms · sync-guard       │
└─────────────────────────────────────────────────────────────────┘
```

### 3.1 Sync engine (Cloud Plan)

- Every row: `id` (UUIDv7), `updatedAt`, `deletedAt` (soft delete), `deviceId`.
- **Outbox pattern:** local writes also append to `sync_outbox`; a background
  worker pushes when online, pulls with an `(updated_at, id)` cursor.
- **Conflicts:** last-write-wins per row for catalog data (products, customers).
  Stock is never synced as a number — it is derived from append-only
  `stock_movements`, which merge conflict-free across devices.
- Sales/purchases are immutable after finalization (corrections = returns /
  adjustments), so they never conflict.

### 3.2 Licensing & activation

- One-time license = signed key (Ed25519) bound to shop + machine fingerprint;
  verified fully offline. Activation online once (or by phone-issued code).
- Cloud Plan = Supabase subscription flag checked opportunistically with a
  30-day offline grace; expiry degrades gracefully to local-only (never locks
  the POS).

### 3.3 Hardware

- **Barcode scanner:** USB HID keyboard-wedge (universal in BD) — a global
  keystroke listener detects scan bursts ending in Enter; no drivers needed.
- **Thermal printer:** ESC/POS 58mm & 80mm templates; USB (Windows), Bluetooth
  (Android), and LAN. Shop logo rendered as raster bitmap header; bill footer =
  shop phone/address + "Powered by BechaKena".
- **Cash drawer:** kick pulse via printer (standard ESC/POS `DLE DC4`).

## 4. Data model (Drift/SQLite, mirrored in Postgres)

All tables carry `id`, `updatedAt`, `deletedAt`, `deviceId`.

| Table | Key fields |
|---|---|
| `shops` | name, nameBn, logoPath, address, phone, vatRate, receiptFooter, invoicePrefix |
| `staff` | name, pin (hashed), role: owner/manager/cashier |
| `categories` | name, nameBn, color, sortOrder |
| `products` | barcode, sku, name, nameBn, categoryId, unit (pcs/kg/L…), salePrice, costPrice, vatRate, lowStockLevel, imagePath, isActive |
| `stock_movements` | productId, qtyDelta, type: sale/purchase/adjustment/return, refId, expiryDate?, note — **append-only; stock = SUM(qtyDelta)** |
| `customers` | name, phone, address, smsOptIn — due = derived from sales.due − duePayments |
| `sales` | invoiceNo, staffId, customerId?, subtotal, discount, vat, total, paid, due, status |
| `sale_items` | saleId, productId, nameSnapshot, qty, unitPrice, lineDiscount, lineTotal |
| `sale_payments` | saleId, method: cash/bkash/nagad/card/due, amount, refNo |
| `due_payments` | customerId, amount, method, note — pays down baki |
| `suppliers` | name, phone, address |
| `purchases` / `purchase_items` | supplierId, invoice info / productId, qty, unitCost, expiryDate? |
| `sms_log` | customerId, phone, kind: receipt/due_reminder, body, status |
| `sync_outbox` | tableName, rowId, op, payload, queuedAt |
| `settings` | key/value (locale, printer config, license blob…) |

**Derived views:** current stock per product, customer due balance, daily/weekly
/monthly sales & profit, top products, low-stock list, expiring-soon list.

## 5. V1 feature spec

### 5.1 POS screen (the flagship)
- **Left: floating product grid** — animated cards (image, name, price, stock
  badge), live fuzzy search (Bangla + English + barcode), category chips,
  staggered entrance animations.
- **Right: invoice sidebar** — line items with qty steppers, per-line & bill
  discount, VAT, running total in ৳; sticky pay bar.
- **Four add-to-cart paths:** barcode scan · grid tap · search select · manual
  entry (name + price for unlisted items). Drag a card onto the invoice as a
  polished fifth path.
- **Checkout:** split payments (cash/bKash/Nagad/card/due), change calculation,
  optional customer attach (required if any amount goes to due), print + SMS.

### 5.2 Products & inventory
CRUD with Bangla names, barcode assign/generate, bulk import (CSV), purchase
entry restocks with expiry dates, manual adjustments with reason, low-stock &
expiring-soon dashboards.

### 5.3 Baki khata (customers)
Customer list with due balances, per-customer statement (sales + payments),
receive-payment flow, SMS receipt on sale and due reminder (manual send in v1;
scheduled in v1.1). SMS via BD gateway aggregator behind an edge function.

### 5.4 Reports
Today at-a-glance (sales, profit, transactions, due collected), date-range
reports, top products, staff-wise sales, VAT summary. Export CSV/PDF.

### 5.5 Settings
Shop profile + logo, receipt designer (58/80mm preview), printer setup + test
print, staff & PINs, বাংলা/English toggle, backup/restore file, license &
Cloud Plan status.

## 6. Modules

The app is a **multi-module POS**. After login the operator picks a module for
the session (`lib/app/business_type.dart`); the choice scopes the catalog and
navigation and resets on logout. Products/categories carry a `businessType`
tag so each module keeps a separate catalog on one install.

- **Supershop / retail** — the flagship POS (§5): grid → cart → split-tender
  checkout, baki khata, inventory, purchases, reports.
- **Restaurant** — menu catalog + a **dining floor** (`DiningTables`) with live
  free/occupied status, and **running orders** (`DineOrders` / `DineOrderItems`)
  for dine-in, takeaway and delivery. Waiters build a tab that persists across
  navigation, fire a **Kitchen Order Ticket** (KOT) for the new lines, then
  settle — which finalizes an immutable `Sales` row through the *same* engine as
  retail, so restaurant sales flow into history, reports and per-branch stock
  identically. Free/occupied is derived from open orders; nothing is stored.

### 6.1 Still on the roadmap
Supplier payables aging, weighing-scale integration, web owner dashboard,
marketplace integrations, Web3 attestations (architecture keeps IDs/receipts
signable so this can bolt on later).

## 7. Quality bar
- `flutter analyze` clean; unit tests for money math, stock derivation, sync
  merge, invoice numbering; golden tests for receipt layouts.
- All money in integer paisa; all timestamps UTC; UI renders in shop-local time.
- Every screen ships in both `bn` and `en` from day one.
