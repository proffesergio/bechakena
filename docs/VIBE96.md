# Vibe96 submission — BechaKena

## Short description (as submitted)

> Offline-first retail and restaurant POS built with Flutter/Dart and Drift/SQLite. Barcode checkout, inventory, baki khata, purchasing, reports, tables and kitchen tickets. Bangla/English UI; Windows, Android, iOS and browser demo. Cloud sync is roadmap-only.

— Within the 300-character listing limit. Cloud features are explicitly roadmap-only.

What the blurb covers for review:

| Required item | Covered by |
|---|---|
| What it does & for whom | Offline-first retail and restaurant POS |
| Main modules | Barcode checkout, inventory, baki khata, purchasing, reports, tables and kitchen tickets |
| Language & framework | Dart / Flutter |
| Database | Drift over local SQLite |
| Web / mobile apps | Windows, Android, iOS + web (browser demo) |

Build, test and setup instructions are intentionally out of scope here — see
`HowToSetup.md`.

## Submission fields

| Field | Value |
|---|---|
| Category | **Ecommerce & Retail** |
| Landing page URL | `https://bkpos.vercel.app/` |
| Live demo URL | `https://bkpos.vercel.app/demo/` |
| Demo access | Choose Retail or Restaurant, take or skip the tour, then create a browser-local owner name and PIN; load sample items to try a sale. Data stays in the visitor's browser |

## Category

**Ecommerce & Retail** — recommended.

BechaKena is a point-of-sale system: its core loop is completing in-store sales
for shops and restaurants, with inventory and purchasing attached. That is
retail software, which is exactly what this category lists.

**Sales & Marketing is not a fit.** That category is aimed at lead generation,
CRM and campaign tools; BechaKena processes transactions rather than acquiring
or nurturing customers.

If vibe96 offers a Restaurant/Hospitality category, BechaKena's restaurant
mode (dining tables, kitchen tickets) would also qualify there — but
Ecommerce & Retail remains the primary listing.

## Archive layout

The submission ZIP mirrors the repository layout one-to-one, so every path in
`HowToSetup.md` resolves exactly as written. Mapping to the checker's structure:

| Checker slot | In this archive |
|---|---|
| `README.md`, `HowToSetup.md`, `CLAUDE.md`, `CHANGELOG.md`, `LICENSE-NOTE.md`, `.env.example` | repository root |
| `Project/` (the web application) | `site/` (Next.js landing + demo host) + `scripts/` + `docker/` |
| `Flutter APP/` (the app) | repository root — `lib/`, `test/`, `assets/`, `android/`, `ios/`, `linux/`, `windows/`, `web/`, `pubspec.*` |
| `database/` | `database/` (`schema.sql`, `seed.sql`, `README.md`) |
| `mobile/README.md` | `mobile/README.md` — build notes pointing at the Flutter project at the root |
| `docker-compose.yml` | repository root (builds via `docker/Dockerfile`) |
| `docs/` | `docs/` |

## Components — complete source, no hidden admin/API

| Component | Source paths | Notes |
|---|---|---|
| Flutter POS (product) | `lib/`, `test/`, `assets/`, `android/`, `ios/`, `linux/`, `windows/`, `web/`, `pubspec.yaml`, `pubspec.lock` | Owner/manager back-office screens are part of this app. The Windows runner ships full C++ sources (`main.cpp`, `flutter_window.*`, `win32_window.*`, `utils.*`, `Runner.rc`, `resource.h`, `runner.exe.manifest`, `resources/app_icon.ico`) plus CMake. |
| Marketing/showcase | `site/` | Next.js static export (`output: "export"`); no route handlers or API routes. |
| Database | `database/` | `schema.sql` (v9, 21 tables), `seed.sql`, generation notes. |
| Build/package/deploy | `scripts/`, `tool/`, `docker/`, `.github/`, `docker-compose.yml` | Archive packager, schema/seed dumpers, Docker/nginx, CI and release workflows. |
| Mobile notes | `mobile/README.md` | Points at the single Flutter project at the root; source is not duplicated. |

**There is no separate admin app, server API, Edge Function or hosted database
source in this submission.** Admin/back-office functions are role-gated screens
inside the Flutter binary; the optional Cloud Plan is roadmap-only.

## Requirement compliance

| Requirement | Where it is satisfied |
|---|---|
| 1. Complete source, no compiled-only parts | Full Flutter tree incl. every platform runner, `site/`, `database/`, `scripts/`, `docker/`; **no separate admin/API component exists**. See the component table above and `README.md#source-map--every-component` |
| 2. No real credentials | Only `.env.example` and documentation placeholders; no live `.env*`, tokens or keys staged |
| 3. Builds from a clean machine | `HowToSetup.md` **Clean-machine quickstart** has exact restore, `sqlite3` schema/seed, run and verify commands. ZIP excludes `.git`, `build/`, `.dart_tool`, `node_modules`, `pyenv`, `site/out`, `site/.next`, `.vercel`, `dist` |
| 4. Database script | `database/schema.sql` (schema v9, 21 tables) + `database/seed.sql` demo data |
| 5. Auth & roles | **No networked mutating endpoint ships.** There is no HTTP API, route handler, Edge Function, `ServerSocket`/`HttpServer` or separate admin/API source. All writes go to local SQLite; every local mutation is gated by the session's capability matrix (`lib/features/auth/logic/permissions.dart`). The optional LAN printer uses an outbound socket to a configured printer, accepts no connection and sends no database rows. Client-side RBAC is not a network security boundary. The Cloud Plan backend is roadmap-only |
| 6. Pinned deps, no critical CVEs | `pubspec.lock` + `site/package-lock.json`; `npm audit` → 0 vulnerabilities; `flutter pub outdated` + OSV scan of all 126 hosted Pub packages (five SDK packages excluded) → 0 advisories. Raw evidence: `docs/dependency-audit/`, summarized in `docs/SECURITY.md#dependency-audit` |
| 7. Documentation set | `README.md`, `HowToSetup.md`, `CLAUDE.md`, `CHANGELOG.md` at the ZIP root; `docs/SECURITY.md`, `AUDIT_RESPONSE.md` and dependency evidence included |
| 8. Working live demo | `https://bkpos.vercel.app/demo/` — first use creates a browser-local owner and PIN, then sample items can be loaded |
| 9. Mobile buildable, configurable API | Flutter project root + `mobile/README.md`; optional cloud API base URL in `lib/app/config.dart` (roadmap only — no backend ships); icons in `android/` + `ios/` |

## Before submitting

1. Build the archive (validates required files, refuses build junk or env files):

   ```bash
   python scripts/make_submission_zip.py # → dist/bechakena-vibe96.zip
   ```

2. Repo hygiene (already applied in this repository): `site/package-lock.json`
   is tracked; `pyenv/` and `graphify-out/` are untracked and gitignored —
   re-check with `git status` if you add files.

3. Upload `dist/bechakena-vibe96.zip` at vibe96.com/sell/submit.

4. Use `https://bkpos.vercel.app/` for the **landing page** and
   `https://bkpos.vercel.app/demo/` for the **live POS demo**. Publish the updated
   build before resubmitting; local changes do not change the hosted website.

5. Upload `site/public/media/cover.png` as the cover and
   `site/public/media/landing-square.png` as the square landing image.
   See [RESUBMISSION.md](RESUBMISSION.md) for the review evidence and remaining
   publication steps. Final approval requires a fresh Vibe96 review.
