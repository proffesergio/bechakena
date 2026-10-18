# How to set up BechaKena

BechaKena is one Flutter codebase plus an optional web showcase. Pick the
target that matches what you want to run:

| Target | What runs | Best for |
|---|---|---|
| **A. VPS, native** | Landing page + browser demo behind nginx | Public demo on a server you own |
| **B. Docker** | Same, built and served from one container | One-command deploy, clean-machine builds |
| **C. Windows shop PC** | The POS itself (offline, local SQLite) | The actual product in a shop |
| **D. Android phone/tablet** | The POS itself, API-configurable | Mobile billing, restaurant floor use |

Every target starts from the same repository. Nothing in the POS requires
network access; the cloud (Supabase) is optional and configured at build time.

---

## 0. Prerequisites

| Tool | Version | Needed for |
|---|---|---|
| Flutter SDK | 3.47.7+ (stable) | A, B, C, D |
| Node.js + npm | 22+ | A, B (showcase landing page) |
| Python 3 | 3.10+ | A, B (packaging check only) |
| nginx | 1.24+ | A |
| Docker + Compose | v2 | B |
| Visual Studio **Desktop development with C++** | 2022 | C (Windows builds) |
| Android Studio / Android SDK | current | D |

Full platform build details (installers, code signing, iOS) live in
[`docs/BUILD.md`](docs/BUILD.md). Day-to-day app usage lives in
[`docs/OPERATIONS.md`](docs/OPERATIONS.md).

Get the code:

```bash
git clone <repo-url> bechakena && cd bechakena
```

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
dart run build_runner build --delete-conflicting-outputs
flutter build web --release --base-href /demo/ --no-web-resources-cdn

npm --prefix site ci
npm --prefix site run build
```

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
dart run build_runner build --delete-conflicting-outputs
flutter run -d windows            # dev
flutter build windows --release   # build\windows\x64\runner\Release\bechakena.exe
```

Cutting a release from git:

```bash
git tag v1.0.0 && git push origin v1.0.0   # CI attaches Windows .zip + Android .apk
```

---

## D. Android phone/tablet (configurable API)

```bash
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
to install and nothing to migrate by hand. The repository includes the scripts
for tooling, backups, analytics and reviewers:

| File | Purpose |
|---|---|
| `database/schema.sql` | Complete schema (v6, 21 tables) that creates a database from scratch |
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
sqlite3 bechakena_superShop.db < database/schema.sql
sqlite3 bechakena_superShop.db < database/seed.sql
```

Then launch the app and sign in as **Demo Owner / PIN 1234** (see §6).

**Backups:** Settings → Backup now writes a clean snapshot; Restore picks one
up on the next launch. The seeded database passes `PRAGMA integrity_check`
and is covered by `flutter test test/core/db/schema_seed_test.dart`.

**Optional cloud (Cloud Plan):** multi-device sync mirrors each row into
Supabase Postgres; the app keeps working forever without it. Setup steps:
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
definitions, re-run the schema dump: `dart run tool/dump_schema.dart`.

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

---

## Verify the setup

```bash
flutter analyze                       # must stay clean
flutter test                          # unit + widget + schema/seed scripts
```

The web demo is healthy if `/demo/` loads, offers the module picker, and can
add a product to the cart with the network disconnected.
