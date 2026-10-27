# BechaKena showcase

Bilingual Next.js static marketing site at `/`, with the Flutter browser demo at `/demo/`.

**Component scope:** this is a static export (`output: "export"`). `app/`
contains only page/layout/robots/sitemap and CSS — there are **no route
handlers, API routes or server actions**, and no separate admin backend. The
browser demo writes only to the visitor's IndexedDB. Dependency evidence:
`../docs/SECURITY.md#dependency-audit`.

Version 1.0.3 uses a light product-led landing page and includes marketplace
artwork: `public/media/cover.png` (1920×1080) and `landing-square.png`
(1080×1080). Editable SVGs and `../scripts/make_listing_media.py` accompany the
PNGs. Use `/` as the listing landing URL; keep `/demo/` as the interactive demo.
Submission evidence and publication steps: `../docs/RESUBMISSION.md`.

```sh
npm ci
npm run dev
npm run build
npm run typecheck
npm test
```

Run these commands from `site/`. `npm run build` exports the site to `out/`. Serve that directory as static files; `next start` does not serve a static export. For local development, the landing page needs actual product captures in `public/media/`: `pos-en.png`, `pos-bn.png`, `restaurant.png`, `reports.png`, `receipt.png`, and `showcase.webm`. Capture the real app with sample records. Do not substitute fabricated shop results.

To package the complete deployment, run from the repository root with Flutter 3.47, Node.js 22, npm, and Python 3 available:

```sh
flutter pub get
flutter gen-l10n
dart run build_runner build
flutter build web --release --base-href /demo/ --no-web-resources-cdn
npm --prefix site ci
npm --prefix site run build
npm --prefix site run typecheck
python3 scripts/prepare_vercel.py
```

The packager copies only `site/out/` and `build/web/` into `.vercel/output/static/`, with Flutter under `demo/`. Do not copy Flutter into `site/public/demo/`. It rejects missing or stale captures, incomplete builds, a wrong Flutter base path, invalid WebAssembly signatures, symlinks, and common private/source files. Flutter's `.last_build_id` is omitted. Builds and all files in `site/public/` must contain public data only.

The generated Vercel Build Output API configuration redirects `/demo` to `/demo/`, serves WebAssembly with its proper MIME type, and applies cross-origin isolation to demo resources. Known Flutter deep links resolve within `/demo/`. Missing assets and unknown landing-page paths return the exported 404 page. There is no site-wide app fallback. The public demo uses browser-local visitor data.

The `Showcase deploy` GitHub Actions workflow builds and uploads the validated package on pushes to `main`. It requires the captures above to be committed. Pushes and manual runs default to production deployment; select `none` on a manual run for packaging only, or `preview` for a preview deployment. Configure repository secrets `VERCEL_TOKEN`, `VERCEL_ORG_ID`, and `VERCEL_PROJECT_ID` for the intended Vercel project before deploying. The workflow does not create or configure the Vercel project. To deploy an already packaged local build, run `vercel deploy --prebuilt` from the repository root with the intended project linked (add `--prod` for production).

Vercel Analytics is installed in the marketing layout using `@vercel/analytics/next`. It records website analytics when enabled for the Vercel project; no POS transaction records or custom form events are sent by this integration. No contact backend, sign-in or payment collection is installed. Contact links open WhatsApp or email. The locale, sample receipt and replenishment controls run in the visitor’s browser without writing POS settings. The receipt preview uses two-decimal currency examples and integer minor-unit tax calculations; it does not convert money or certify a local tax setup. The replenishment scenario illustrates 28-day demand with configurable lead and cover days, clearly separate from live inventory. The actual POS supports English and Bengali; cloud backup and sync remain roadmap items. Sample calculations have focused tests (Node.js 22.18+ or 24 recommended).
