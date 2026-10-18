# BechaKena showcase

Bilingual Next.js static marketing site at `/`, with the Flutter browser demo at `/demo/`.

```sh
npm ci
npm run dev
npm run build
npm run typecheck
```

Run these commands from `site/`. `npm run build` exports the site to `out/`. Serve that directory as static files; `next start` does not serve a static export. For local development, the landing page needs actual product captures in `public/media/`: `pos-en.png`, `pos-bn.png`, `restaurant.png`, `reports.png`, `receipt.png`, and `showcase.webm`. Capture the real app with sample records. Do not substitute fabricated shop results.

To package the complete deployment, run from the repository root with Flutter 3.44, Node.js 22, npm, and Python 3 available:

```sh
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter build web --release --base-href /demo/ --no-web-resources-cdn
npm --prefix site ci
npm --prefix site run build
npm --prefix site run typecheck
python3 scripts/prepare_vercel.py
```

The packager copies only `site/out/` and `build/web/` into `.vercel/output/static/`, with Flutter under `demo/`. Do not copy Flutter into `site/public/demo/`. It rejects missing or stale captures, incomplete builds, a wrong Flutter base path, invalid WebAssembly signatures, symlinks, and common private/source files. Flutter's `.last_build_id` is omitted. Builds and all files in `site/public/` must contain public data only.

The generated Vercel Build Output API configuration redirects `/demo` to `/demo/`, serves WebAssembly with its proper MIME type, and applies cross-origin isolation to demo resources. Known Flutter deep links resolve within `/demo/`. Missing assets and unknown landing-page paths return the exported 404 page. There is no site-wide app fallback. The public demo uses browser-local visitor data.

The `Showcase package and deployment` GitHub Actions workflow builds and uploads the validated package on relevant pushes to `main`. It requires the captures above to be committed. A manual run defaults to packaging only; choose `preview` or `production` to deploy that package with Vercel CLI. Configure repository secrets `VERCEL_TOKEN`, `VERCEL_ORG_ID`, and `VERCEL_PROJECT_ID` for the intended Vercel project before deploying. The workflow does not create or configure the Vercel project. To deploy an already packaged local build, run `vercel deploy --prebuilt` from the repository root with the intended project linked (add `--prod` for production).

No analytics, contact backend, sign-in or payment collection is installed. Contact links open WhatsApp or email. The locale and formatting controls run in the visitor’s browser. Currency previews illustrate formatting and do not imply additional POS currencies or country integrations.
