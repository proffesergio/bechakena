# ─────────────────────────────────────────────────────────────────────────────
# BechaKena showcase — clean-machine Docker build.
#
# Stage 1 compiles the Flutter web demo (same steps as CI), stage 2 exports
# the Next.js landing page, stage 3 serves both from nginx:
#   /        → landing page
#   /demo/   → the Flutter POS running fully in the browser (local data)
#
# Build from the repository root:
#   docker build -f docker/Dockerfile -t bechakena-showcase .
# Or with compose (docker-compose.yml at the repository root):
#   docker compose up -d --build
# ─────────────────────────────────────────────────────────────────────────────

# ── Stage 1: Flutter web demo ────────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:3.47.7 AS flutter-build

WORKDIR /app
COPY pubspec.yaml pubspec.lock l10n.yaml analysis_options.yaml ./
RUN flutter pub get

COPY lib ./lib
COPY web ./web
COPY assets ./assets
COPY tool ./tool
COPY test ./test
COPY database ./database
RUN flutter gen-l10n && \
    dart run build_runner build --delete-conflicting-outputs && \
    flutter analyze && flutter test && \
    flutter build web --release --base-href /demo/ --no-web-resources-cdn

# ── Stage 2: Next.js static landing page ─────────────────────────────────────
FROM node:22.23.3-alpine AS site-build

WORKDIR /app
COPY site/package.json site/package-lock.json ./
RUN npm ci

COPY site ./
RUN npm test && npm run build && npm run typecheck

# ── Stage 3: serve the packaged showcase ─────────────────────────────────────
FROM nginx:1.27-alpine

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=site-build /app/out /usr/share/nginx/html
COPY --from=flutter-build /app/build/web /usr/share/nginx/html/demo

EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -q -O /dev/null http://127.0.0.1/ || exit 1
