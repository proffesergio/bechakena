# BechaKena 1.0.3 — Vibe96 resubmission

Audit #1051 and #972 follow-up evidence: [AUDIT_RESPONSE.md](../AUDIT_RESPONSE.md).
The older audit #349 mapping below is historical; the current release uses schema v9.

Prepared for SUB-2026-1043. The human notice names B0064-43201; audit run #349
names B0064-53050. Keep those references separate when requesting re-review.
This document records changes and source evidence; it is not an approval or a
claim that Vibe96 has rerun its checks.

## Listing and media

| Field | Value / file |
| --- | --- |
| Landing page | `https://bkpos.vercel.app/` — product presentation |
| Live demo | `https://bkpos.vercel.app/demo/` — interactive Flutter POS |
| Demo first use | Choose Retail or Restaurant, take or skip the tour, then create a browser-local owner name and PIN; load sample items to try a sale |
| Cover | `site/public/media/cover.png` — 1920×1080, 16:9 |
| Square landing image | `site/public/media/landing-square.png` — 1080×1080, 1:1 |
| Source archive | `dist/bechakena-vibe96.zip` |
| Integrity digest | `dist/bechakena-vibe96.zip.sha256` |
| Editable artwork | `site/public/media/cover.svg`, `landing-square.svg` |

Both images show the product purpose, real retail UI with sample records,
key features and actual technology. Neither includes contact details, websites
or social links. The square artwork is a designed landing preview, not a full
page browser screenshot. Approved-example links were not supplied in the notice.

The landing page now leads with the offline retail/restaurant purpose and real
checkout capture. It includes first-use demo instructions, a four-tab
product tour, baki khata and inventory features, retail/restaurant workflows,
technology, editable receipt and stock-planning samples, ownership information,
FAQs and contact actions. Bangla/English, keyboard-operated tabs, labelled
controls, skip link and reduced-motion support are retained. Developer query
visualizations were removed to keep the presentation about the product.

Use the listing description in `docs/VIBE96.md`. Cloud sync, cloud backup,
remote owner access and activation services must not be advertised as delivered.
Recorded bKash/Nagad/card tender is not payment processing. Browser hardware
printing is not offered. Native printer support depends on platform/equipment.

## Audit #1051: requirement evidence

Run #1051 stopped at the must-have list (0/100): one must-have missing (R5)
and two partial (R1, R3); R6 was partial. Fixes in this version:

| Audit item | Disposition and evidence |
| --- | --- |
| R1 complete source — partial | Added a component/source map to `README.md` and `docs/VIBE96.md`. The archive now proves every component: Flutter app and all platform runners (including the full Windows C++ runner), `site/` static export, `database/`, `scripts/`, `tool/`, `docker/`, `.github/`. Documented explicitly that **no separate admin app or API/backend exists**; back-office screens are role-gated parts of the same Flutter app. |
| R3 clean machine — partial | Added **Clean-machine quickstart** at the top of `HowToSetup.md`: exact `flutter pub get` / codegen, `sqlite3` schema + seed (with `user_version`/`integrity_check` verification and the Windows app-support path), `flutter run`/build, and `flutter analyze`/`flutter test`. Documented that the ZIP excludes `build/` and `.dart_tool/` (plus caches, generated Dart, env files) and the packager enforces it. |
| R5 auth on mutating endpoint — missing | No networked mutating endpoint exists. `docs/SECURITY.md` now states R5 directly: zero HTTP APIs, route handlers, Edge Functions or separate admin/API source; both runnable parts and their write paths are listed. Local RBAC gates every local mutation, and the docs state that client-side RBAC is not a network security boundary. The same scope appears in `README.md`, `HowToSetup.md`, `site/README.md` and `AUDIT_RESPONSE.md`. |
| R6 pinned deps — partial | Added captured evidence under `docs/dependency-audit/` and summarized it in `docs/SECURITY.md`: `npm audit` = 0 vulnerabilities (64 deps); `flutter pub outdated` output; OSV scan of all 126 hosted Pub packages (five SDK packages excluded) = 0 advisories. Lockfiles remain committed and pinned. |

## Audit #349: requirement evidence

Most technical changes below were already in this checkout before the 1.0.1
presentation update. The older audit sometimes describes a different source
state, including a bcrypt implementation that this project does not use.

| Audit item | Current source / disposition |
| --- | --- |
| R1 complete source | Flutter at repository root, Next.js in `site/`, SQL in `database/`, deployment source in `scripts/` and `docker/` |
| R2 credentials | Only placeholder `.env.example` is packaged; private env files, key/certificate files, local databases and tool output are excluded |
| R3 clean build | `HowToSetup.md` prerequisites and main build flow; both lockfiles included; generated Dart files regenerated before building |
| R4 database | `database/schema.sql` + `seed.sql`, schema version 9; application/migrations in `lib/core/db/database.dart` |
| R5 auth/backend scope | `HowToSetup.md` and `docs/SECURITY.md`: local POS only; no deployed API/backend/Edge Functions ship; optional backend is roadmap-only |
| R6 demo | Keep the existing `/demo/` app separate from `/` marketing; verify hosted version after deployment |
| R7 mobile | `mobile/README.md`, platform source and configurable `lib/app/config.dart`; no server secrets in client defines |
| R8 documentation | Root README, HowToSetup, CLAUDE, CHANGELOG, environment example and platform/database guides included |
| 2.1–2.3 dependencies | Existing lockfiles retained. Current site install audit reports zero vulnerabilities; no untested blanket Flutter dependency upgrade |
| 3.1 customer scope | `lib/features/auth/logic/access.dart`, scoped customer providers, guards on customer payment/reminder dialogs |
| 3.2 purchase scope | `purchasesProvider` reads `readScopeBranchProvider`; purchase list is scoped, with no arbitrary purchase-ID detail route |
| 3.3 sale scope | History list scoped to branch; receipt/detail dialog checks `canViewBranch` before loading/rendering items |
| 3.4 PIN work factor | Existing `pin.dart` uses PBKDF2-HMAC-SHA256 with 600,000 iterations, legacy upgrade path and session lockout; bcrypt cost change is inapplicable |
| 4.1–4.4 indexes | Product foreign-key indexes in schema and v7 migration; v8 adds remaining foreign-key and branch hot-path indexes |
| 4.5–4.6 SQL | Audit explicitly says no fix needed; parameterized queries and scoped deletes retained |
| 5.1 generated files | `.gitignore` and ZIP rules exclude `.g.dart` / `.freezed.dart`; setup and CI regenerate them |
| 5.2–5.4 pricing/receipt/finalization | Existing `lib/core/pricing/pricing.dart`, `printing/receipt_data.dart` and `core/sales/sale_finalizer.dart` |
| 5.5–5.7 UI/RBAC | Existing POS/reports child widgets and `lib/core/auth/rbac.dart`; permission providers reuse the policy |
| 5.8–5.9 formatting/theme | Small existing modules retained; the audit's speculative size-based split is unnecessary |
| 5.10, 5.16 printing | `escpos.dart` creates bytes; `printer_transport.dart` sends them; `logo_raster.dart` returns printer-independent `RasterBitmap` |
| 5.11–5.14 feature organization | Existing inventory replenishment widget, table order/settle widgets, domain table classes and typed demo product data retained; no speculative factory/layer added |
| 5.15 configuration | `lib/app/config.dart` reads optional public identifiers from `String.fromEnvironment`; server-secret warning documented |
| 6.1–6.5 setup/build | Prerequisites name Flutter 3.47.7 and its bundled Dart SDK; main steps regenerate sources; SQL inspection/seed steps documented; `next build` uses no webpack flag; local web resources flag explained |

## Rebuild and verify

From `site/`: `npm ci`, `npm run build`, `npm run typecheck`, `npm test`.
From the repository root:

```sh
python -m unittest discover -s scripts -p 'test*.py'
python scripts/make_submission_zip.py
```

The ZIP uses current working-tree files, validates required sources and media,
checks integrity and excludes private/config/build/cache files. Its contents
mirror the documented repository layout. The Bash entry point delegates to the
same Python rules. Artwork can be regenerated with:

```sh
uv run --with pymupdf python scripts/make_listing_media.py
```

Validation on this machine: Next.js production export and TypeScript succeed;
five site tests, three ZIP regression tests and existing public-output safety
tests pass. The shipped SQL was executed with Python's `sqlite3` module:
`user_version` = 9, `integrity_check` = ok, 21 tables, 0 FK violations, seed
rows loaded. Static export anchors, image alt text,
media freshness, archive file equality and SHA-256 were checked. Local HTTP checks
return 200 for the refreshed landing page and cover image. Both PNGs were
rendered and visually inspected. The available Flutter SDK is 3.32.5 / Dart 3.8.1,
below this project's requirement, so native compilation and tests run in GitHub
Actions with the pinned Flutter 3.47.7 SDK. See the release workflow runs for
their final status. Browser automation is unavailable
in this session; responsive layouts and interactions need browser QA before review.

## Publish, upload, re-review

1. Build the complete landing + Flutter package with the required SDK using
   `site/README.md` / `.github/workflows/showcase.yml`. Deploy to the existing
   Vercel project, preserving `/demo/`. Do not replace the deployment with only
   `site/out/`, which would remove the POS demo.
2. Verify both hosted URLs, demo login, all tour tabs, video, Bangla toggle,
   contact links, FAQ and sample controls on desktop and phone widths.
3. Edit the Vibe96 landing URL to `/`; keep `/demo/` in the live demo field.
4. Upload the two PNGs above through Edit media and replace the source ZIP.
5. Submit version 1.0.3 for a fresh audit and human review.

The deployment target is confirmed as `n3rd-s-projects/bechakena` (production
alias `bkpos.vercel.app`). The showcase workflow builds both the landing page
and the Flutter demo and uploads deployment and submission ZIP artifacts.
The existing GitHub `VERCEL_TOKEN` secret was rejected in the previous run;
replace it with a valid token for that team to restore automatic deployment.
Step-by-step instructions are in [VERCEL_TOKEN.md](VERCEL_TOKEN.md). The CLI
token-creation attempt was rejected by Vercel (HTTP 403); no secret was changed.
A completed public-output artifact can also be deployed through the linked,
authenticated CLI with `vercel deploy --prebuilt --prod`.

Vibe96 listing edits and media uploads remain separate from Vercel publication.
Vibe96 approval remains the reviewer's decision after the hosted changes and
listing assets are submitted.
