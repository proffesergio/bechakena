# Licence note — BechaKena

**BechaKena** (this repository and the software it builds) is commercial
software by **neWell Software**. It is provided for evaluation and for use by
licensed buyers; it is not open source.

## What a licence covers

- Install and operate the POS for your own shop/restaurant business.
- Modify the source for your own deployment.
- It does **not** cover reselling, redistributing or publishing the source or
  a derivative as a product, in whole or in part, without a written
  distribution agreement with the vendor.

## Demo data & credentials

Everything shipped in `database/seed.sql` is synthetic demo data (Demo Owner /
PIN 1234) so reviewers and buyers can see a working system. Replace it before
real use.

## Third-party components

The product bundles third-party packages that keep their own licences:

- Flutter & Dart SDK — BSD-3-Clause
- Drift, Riverpod, go_router, sqlite3 and the remaining Dart packages — see
  `pubspec.lock` for the exact set; each package ships its own licence
- Next.js and the showcase site packages — MIT; see `site/package-lock.json`
- Noto Sans Bengali font (bundled asset) — SIL Open Font License 1.1

No third-party licence text is hidden or removed.

## Secrets

No real credentials, tokens or keys are included in the archive — only
`.env.example` placeholders. Server-side secrets belong in the server/CI
environment and are configured at build time (see `HowToSetup.md` §Configuration
reference).
