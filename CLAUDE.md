# BechaKena — Claude Code guide

Offline-first supermarket POS for Bangladesh. Flutter (Windows/Android/iOS) +
Drift(SQLite) local source of truth + optional Supabase cloud sync.
Full architecture, data model, and feature spec: **docs/DESIGN.md** — read it
before structural changes.

## Commands
- `flutter pub get` — install deps
- `dart run build_runner build --delete-conflicting-outputs` — regen Drift/Riverpod code (required after editing tables/providers)
- `flutter analyze` — must stay clean
- `flutter test` — unit + widget tests
- `flutter run -d linux` — dev on this machine (Windows is the shipping desktop target)
- `flutter gen-l10n` — regen localizations after editing `lib/l10n/*.arb`

## Layout
- `lib/app/` — router, theme, l10n setup, top-level providers
- `lib/core/` — db (Drift tables/DAOs), sync engine, printing, license, barcode listener, money utils
- `lib/features/<feature>/` — feature-first: `data/`, `logic/` (Riverpod), `ui/`
- `lib/l10n/` — `app_en.arb`, `app_bn.arb` (every string in both, always)

## Hard rules
- **Offline-first:** no feature may require network. Cloud is additive.
- **Money is integer paisa** (`Money` type in `core/money.dart`) — never double.
- **Stock is derived**: `SUM(stock_movements.qtyDelta)`. Never store/overwrite a stock number.
- Finalized sales are immutable — corrections via returns/adjustments.
- Every table row: UUIDv7 `id`, `updatedAt`, `deletedAt`, `deviceId` (sync contract).
- Every user-facing string goes through l10n (bn + en); ৳ formatting via `core/format.dart`.
- Generated files (`*.g.dart`, `*.freezed.dart`) are committed; don't hand-edit.

## Branding
Product name/brand comes from `lib/app/brand.dart` only — never hardcode
"BechaKena" in UI strings; the name may change before launch.
