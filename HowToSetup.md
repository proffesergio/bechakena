# How to set up BechaKena

BechaKena is one Flutter codebase plus an optional web showcase. Pick the
target that matches what you want to run:

| Target | What runs | Best for |
|---|---|---|
| **A. VPS, native** | Landing page + browser demo behind nginx | Public demo on a server you own |
| **B. Docker** | Same, built and served from one container | One-command deploy, clean-machine builds |
| **C. Windows shop PC** | The POS itself (offline, local SQLite) | The actual product in a shop |
| **D. Android phone/tablet** | The POS itself (optional cloud config; no backend ships) | Mobile billing, restaurant floor use |

Every target starts from the same repository. Nothing in the POS requires
network access. Cloud configuration flags are reserved for future development;
they do not enable a working cloud service in this release.

**Component scope:** this archive contains one Flutter app (the POS, including
its owner/manager back-office screens) plus a static Next.js showcase. There is
**no separate admin app, no backend API and no Edge Function source** in the
submission. The POS has no networked mutating endpoint; all writes go to local
SQLite and are gated by local role checks (see
[`docs/SECURITY.md`](docs/SECURITY.md#authorisation--local-only-no-networked-mutating-endpoints-r5)).

---

## 0. Prerequisites

| Tool | Version | Needed for |
|---|---|---|
| Flutter SDK | 3.47.x (stable; tested 3.47.7) | A, B, C, D |
| Dart SDK | 3.13.5 bundled with Flutter 3.47.7; project requires >=3.12.2 <4.0.0 | A, B, C, D |
| Node.js + npm | 22.18+ (22.x) or 24.x | A, B (showcase landing page) |
| Python 3 | 3.10+ | A, B (packaging check only) |
| `sqlite3` CLI | 3.35+ (optional) | Database fixture / review machines |
| nginx | 1.24+ | A |
| Docker + Compose | v2 | B |
| Visual Studio **Desktop development with C++** | 2022 | C (Windows builds) |
| Android Studio / Android SDK | current | D |

The submission archive uses Python 3 only: `python scripts/make_submission_zip.py`.
The archive excludes generated sources; always run the generators below.

Full platform build details (installers, code signing, iOS) live in
[`docs/BUILD.md`](docs/BUILD.md). Day-to-day app usage lives in
[`docs/OPERATIONS.md`](docs/OPERATIONS.md).

Get the code:

```bash
git clone <repo-url> bechakena && cd bechakena
```

---

## Clean-machine quickstart (copy/paste)

This is the exact sequence from a fresh machine or a freshly unzipped
`bechakena-vibe96.zip`. It restores dependencies, generates the Drift/Riverpod
and localization sources, creates the SQLite database from the shipped scripts,
and starts the POS. Run the commands from the repository root.

**1. Confirm the toolchain** (use Flutter 3.47.7 and its bundled Dart SDK):

```bash
flutter --version
node --version      # only needed for the optional site/ showcase
sqlite3 --version   # only needed for the database fixture steps below
```

**2. Restore dependencies and generate sources.** The ZIP deliberately omits
generated Dart (`*.g.dart`, `*.freezed.dart`) and local caches; this recreates
them:

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build
```

**3. Create and seed SQLite from the shipped scripts** (optional, for a review
machine or a pre-seeded demo). The app normally creates its own database on
first launch; these commands create the exact same schema and demo data:

```bash
sqlite3 review.db < database/schema.sql
sqlite3 review.db < database/seed.sql
sqlite3 review.db "PRAGMA user_version; PRAGMA integrity_check;"
# expected output: 9, then ok
```

To make the Windows app open that demo on first launch, create the module file
in its app-support directory before starting the app. Use this only on a fresh
review installation; do not import demo SQL into an existing shop database.
PowerShell uses SQLite's `.read` command instead of shell input redirection:

```powershell
New-Item -ItemType Directory -Force "$env:APPDATA\com.newell\bechakena"
$reviewDatabase = "$env:APPDATA\com.newell\bechakena\bechakena_superShop.db"
if (Test-Path -LiteralPath $reviewDatabase) { throw 'Use a fresh review installation.' }
sqlite3 -bail "$reviewDatabase" ".read database/schema.sql" ".read database/seed.sql" "PRAGMA user_version; PRAGMA integrity_check; PRAGMA foreign_key_check;"
# expected output: 9, then ok, with no foreign-key violations
```

On Android the equivalent directory is app-private storage; the simplest path
is to launch the app and load sample data from **Settings → Load sample
products**, or restore a backup made from another install.

**4. Run the POS:**

```bash
flutter run -d windows            # shipping desktop target
flutter run -d linux              # Linux development machine
flutter build windows --release   # build\windows\x64\runner\Release\bechakena.exe
```

**5. Verify the checkout:**

```bash
flutter analyze
flutter test
```

**What the submission ZIP excludes.** `python scripts/make_submission_zip.py`
skips `.git/`, `build/`, `.dart_tool/`, `node_modules/`, `site/.next/`,
`site/out/`, `.vercel/`, `dist/`, local databases, private env files and
generated `*.g.dart` / `*.freezed.dart` files. It also fails the build if a
required source or document is missing, so the archive always contains the
complete source tree described in [README.md](README.md#source-map--every-component).

---

Common first steps for every target:

```bash
flutter pub get
flutter gen-l10n                                          # bn + en strings
dart run build_runner build  # Drift + Riverpod code
flutter analyze
flutter test
```

On an empty native installation, create the first owner and open **Settings**
before importing products or loading sample data. Select the shop currency
(BDT/USD/EUR/GBP/AED/SAR/INR/CAD/AUD/SGD/MYR/PKR), tax label and business tax ID.
The currency uses two decimals and is shared by branches within that module.
It locks once priced or financial records exist to preserve historical money.
No foreign exchange or automatic country tax compliance is provided. English
and Bengali language choices persist on the device. The public web demo starts
with BDT as its default currency; sample amounts are not converted. A fresh
browser creates its own owner name and PIN after the module picker and tour.

---

## A. VPS, native (landing page + live demo)

Tested on Ubuntu 24.04. The result: `https://your-domain/` serves the
marketing page and `https://your-domain/demo/` runs the full POS in the
browser with data kept in the visitor's browser only.

**1. Install the toolchain**

```bash
sudo apt-get update && sudo apt-get install -y curl git nginx python3
# Flutter (stable) — follow the archive for your distro, or:
sudo snap install flutter --classic
# Node 22 via nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
source ~/.nvm/nvm.sh && nvm install 22
```

**2. Build both halves**

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build
flutter analyze
flutter test
flutter build web --release --base-href /demo/ --no-web-resources-cdn

npm --prefix site ci
npm --prefix site test
npm --prefix site run build
npm --prefix site run typecheck
```

`--no-web-resources-cdn` bundles CanvasKit and the icon font inside
`build/web/` instead of fetching them from `gstatic.com` at runtime — required
for the offline-first demo (the Docker image and the VPS/nginx setup both
serve it without any external CDN calls).

**3. Publish the files**

```bash
sudo mkdir -p /var/www/bechakena/demo
sudo cp -r site/out/.          /var/www/bechakena/
sudo cp -r build/web/.         /var/www/bechakena/demo/
```

**4. Point nginx at them**

```nginx
server {
    listen 80;
    server_name your-domain.com;
    root /var/www/bechakena;
    index index.html;

    include /etc/nginx/mime.types;
    types { application/wasm wasm; }

    location = /demo { return 308 /demo/; }
    location /demo/ {
        # Drift's web worker needs cross-origin isolation (SharedArrayBuffer).
        add_header Cross-Origin-Opener-Policy same-origin always;
        add_header Cross-Origin-Embedder-Policy require-corp always;
        add_header X-Content-Type-Options nosniff always;
        try_files $uri $uri/ /demo/index.html;
    }

    location / {
        add_header X-Content-Type-Options nosniff always;
        try_files $uri $uri/ /404.html;
    }
}
```

```bash
sudo nginx -t && sudo systemctl reload nginx
```

**5. HTTPS**

```bash
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

**6. Update later** — pull, re-run step 2, re-copy step 3, reload nginx.
`python3 scripts/prepare_vercel.py` additionally validates the build for
Vercel packaging (requires the real product captures in `site/public/media/`,
which the repository ships).

---

## B. Docker (build + serve in one command)

The image compiles the Flutter web demo and the Next.js landing page on a
clean machine and serves both with nginx (`/` and `/demo/`). No local Flutter
or Node install is needed.

**1. Configure (optional)** — copy the template; only `DEMO_PORT` is used here:

```bash
cp .env.example .env        # then edit DEMO_PORT (default 8080)
```

**2. Build and start**

```bash
docker compose up -d --build
```

**3. Open** `http://<server-ip>:8080/` for the landing page and
`http://<server-ip>:8080/demo/` for the live POS demo. The container includes
a health check (`docker ps` shows `healthy`).

**4. Operate**

```bash
docker compose logs -f         # follow logs
docker compose down            # stop
docker compose up -d --build   # rebuild after updates
```

Put TLS in front with nginx/Caddy/traefik, or map the TLS proxy to the
published `DEMO_PORT`. The same `docker/nginx.conf` used inside the image can
be reused as the VPS vhost (change `root` to `/var/www/bechakena`).

> The Docker image is for the **showcase**. The POS itself is a desktop/mobile
> app (targets C and D) — install it where the shop is, not on the VPS.

---

## C. Windows shop PC (the POS)

**From a release** (recommended): download the Windows `.zip` from the
repository's Releases page (built by `.github/workflows/release.yml` on every
`v*` tag), unzip anywhere and run `bechakena.exe`. The optional Inno Setup
installer adds Start-menu entries — see [`docs/BUILD.md` §1c](docs/BUILD.md).

**From source:**

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build
flutter run -d windows            # dev
flutter build windows --release   # build\windows\x64\runner\Release\bechakena.exe
```

Cutting a release from git:

```bash
git tag v1.0.3 && git push origin v1.0.3   # CI attaches Windows .zip + Android .apk
```

---

## D. Android phone/tablet (optional cloud configuration)

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build
flutter analyze
flutter test
flutter build apk --release \
  --dart-define=BECHAKENA_API_BASE_URL=https://your-server.example.com/functions/v1 \
  --dart-define=BECHAKENA_SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=BECHAKENA_SUPABASE_ANON_KEY=your-anon-key
# output: build/app/outputs/flutter-apk/app-release.apk
```

Install the APK (`adb install` or copy to the device). With no `--dart-define`
flags the build is 100% offline — that is the default and fully supported.
Every variable is listed in [`.env.example`](.env.example); the four
`BECHAKENA_*` values are the only ones the app reads (compile-time, via
`lib/app/config.dart`).

iOS needs a Mac + Apple account — see [`docs/BUILD.md` §4](docs/BUILD.md).

---

## Database setup

The POS ships its own database engine (SQLite via Drift); there is no server
to install and nothing to migrate by hand. **The app creates its database on
first launch** — the scripts below are for inspecting the schema or pre-seeding
a demo database on a fixture/review machine:

| File | Purpose |
|---|---|
| `database/schema.sql` | Complete schema (v9, 21 tables) that creates a database from scratch |
| `database/seed.sql` | Demo shop + catalog + customers + sales so a fresh install has data |
| `database/README.md` | How both files are generated and kept identical to the app |

**How the app uses it:** on first launch each module (`Super Shop`,
`Restaurant`) creates its own file in the app-support directory —
`bechakena_superShop.db`, `bechakena_restaurant.db` on Windows/Android — and
applies the same schema the script contains. Stock is always derived
(`SUM(stock_movements.qty_delta)`); finalized sales are immutable.

**Apply the scripts yourself** (optional — for a demo DB, a fixture, or a
review machine):

```bash
sqlite3 review.db < database/schema.sql   # inspect the exact shipped schema
sqlite3 review.db < database/seed.sql     # demo shop, catalog, customers, sales
sqlite3 review.db "PRAGMA user_version; PRAGMA integrity_check;"   # 9, ok
```

For a working demo inside the app, create the module file in the app-support
directory (`%APPDATA%\com.newell\bechakena\bechakena_superShop.db` on Windows)
before first launch, or use the full copy/paste sequence in
[Clean-machine quickstart](#clean-machine-quickstart-copypaste). Then launch the
app and sign in as **Demo Owner / PIN 1234** (see §6).

**Backups:** Settings → Backup now writes a clean snapshot; Restore picks one
up on the next launch. The seeded database passes `PRAGMA integrity_check`
and is covered by `flutter test test/core/db/schema_seed_test.dart`.

**Future Cloud Plan:** multi-device sync and a hosted database remain roadmap
work. No sync transport or backend is implemented; setting URL/key flags does
not enable them. Development scope:
[`docs/OPERATIONS.md` §5](docs/OPERATIONS.md).

---

## First admin login

1. **Launch the app.** First run asks which business you run — Super Shop or
   Restaurant — and remembers it. Each module has its own isolated database,
   staff and reports.
2. **Feature tour** (once), then the **owner account** screen: enter a name and
   a PIN of at least 4 digits. Everything is offline; there is no sign-up and
   no internet call.
3. **Signing in later:** pick your name, enter the PIN.
4. **Add staff:** Settings → Staff & PINs → add a manager or cashier, each with
   their own PIN. Roles are a capability matrix — cashiers see only selling and
   customers; managers add back-office; owners see everything.
5. **Demo database:** if you applied `database/seed.sql`, the pre-created owner
   is **Demo Owner**, PIN **1234** — change it immediately in
   Settings → Staff & PINs before any real use.
6. **Switch module / log out** any time from Settings; the next person signs in
   with their own PIN.

Forgot a PIN: the owner can reset another staff member's PIN from Settings →
Staff & PINs. For a full factory reset (this module only): Settings → Clear
local data, then relaunch.

---

## Branding changes

| What | Where |
|---|---|
| Product name (English / Bangla), company | `lib/app/brand.dart` — the only place the product name lives; never hardcode it in UI strings |
| Shop name, address, phone, receipt footer, logo, invoice prefix | In-app **Settings → Shop profile** (prints on every receipt) |
| App colors / theme | `lib/app/theme.dart` |
| Receipt layout & KOT | `lib/core/printing/receipt.dart`, `kot.dart` |
| Browser tab title + PWA manifest | `web/index.html`, `web/manifest.json` |
| Showcase landing copy (bn + en) | `site/components/copy.ts` |
| Showcase metadata / canonical URL | `site/app/layout.tsx` + `NEXT_PUBLIC_SITE_URL` in `.env.example` |
| Bengali font | `assets/fonts/NotoSansBengali.ttf` (bundled; declared in `pubspec.yaml` + theme fallback) |

After editing any user-facing string, update **both** `lib/l10n/app_en.arb`
and `lib/l10n/app_bn.arb`, then run `flutter gen-l10n`. After changing table
definitions re-run `dart run build_runner build`
(regenerates Drift code), then the schema dump: `dart run tool/dump_schema.dart`.

---

## Configuration reference

Copy `.env.example` → `.env` (tooling only; never commit a filled-in copy).
The app itself takes values at build time:

| Build flag | Meaning |
|---|---|
| `--dart-define=BECHAKENA_API_BASE_URL=…` | Optional Cloud Plan API base URL |
| `--dart-define=BECHAKENA_SUPABASE_URL=…` | Optional Supabase project URL |
| `--dart-define=BECHAKENA_SUPABASE_ANON_KEY=…` | Public anon key (never the service-role key) |
| `--dart-define=BECHAKENA_LICENSE_PUBLIC_KEY=…` | Ed25519 public key for offline license checks |

Server-side secrets (`SUPABASE_SERVICE_ROLE_KEY`, `SMS_API_KEY`, Vercel
tokens) must stay in the server/CI environment and never ship in the app or a
committed file.

**Cloud Plan scope:** the optional Supabase sync layer is roadmap-only. This
archive ships the client-side configuration flags only — no backend or Edge
Functions source, no server secrets. A fully local install is the supported
configuration: skip the `BECHAKENA_SUPABASE_*` flags and the app runs complete
and offline. Backend code, when it exists, is server-side and out of scope for
this submission.

---

## Verify the setup

```bash
flutter analyze                       # must stay clean
flutter test                          # unit + widget + schema/seed scripts
```

The web demo is healthy if `/demo/` loads, offers the module picker, and can
add a product to the cart with the network disconnected.
