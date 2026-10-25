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
| Demo credentials | **Demo Owner · PIN 1234** — pick either module first; data stays in the visitor's browser |

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
| `Flutter APP/` (the app) | repository root — `lib/`, `android/`, `ios/`, `windows/`, `web/`, `pubspec.*` |
| `database/` | `database/` (`schema.sql`, `seed.sql`, `README.md`) |
| `mobile/README.md` | `mobile/README.md` — build notes pointing at the Flutter project at the root |
| `docker-compose.yml` | repository root (builds via `docker/Dockerfile`) |
| `docs/` | `docs/` |

## Requirement compliance

| Requirement | Where it is satisfied |
|---|---|
| 1. Complete source, no compiled-only parts | Flutter app, `site/`, `docker/`, `scripts/` all shipped as source |
| 2. No real credentials | Only `.env.example` placeholders; no `.env*`, tokens or keys staged (secret scan clean) |
| 3. Builds from a clean machine | `HowToSetup.md` targets A–D; the ZIP excludes `.git`, `build/`, `node_modules`, `pyenv`, `site/out`, `.dart_tool`, `.vercel` |
| 4. Database script | `database/schema.sql` (schema v9, 21 tables) + `database/seed.sql` demo data |
| 5. Auth & roles | Offline by design — no HTTP endpoints ship in this archive; every mutation is gated in-app by the session's capability matrix (`lib/features/auth/logic/permissions.dart`), admin areas are role-protected. The optional Cloud Plan backend is roadmap-only: server-side, not part of this submission |
| 6. Pinned deps, no critical CVEs | `pubspec.lock` + `site/package-lock.json`; `npm audit` → 0 vulnerabilities |
| 7. Documentation set | `README.md`, `HowToSetup.md`, `CLAUDE.md`, `CHANGELOG.md` at the ZIP root |
| 8. Working live demo | `https://bkpos.vercel.app/demo/` — Demo Owner / PIN 1234 |
| 9. Mobile buildable, configurable API | Flutter project root + `mobile/README.md`; API in `lib/app/config.dart`; icons in `android/` + `ios/` |

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
