#!/usr/bin/env bash
#
# Builds the submission ZIP for the vibe96 listing from this working tree.
#
#   scripts/make_submission_zip.sh [output.zip]
#
# The ZIP mirrors the repository layout one-to-one (so every path in
# HowToSetup.md resolves) and deliberately excludes git history, build output,
# tool caches and every non-placeholder env file. The script refuses to build
# if a required submission file is missing or a forbidden path is staged.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-$ROOT/dist/bechakena-vibe96.zip}"

command -v rsync >/dev/null || { echo "error: rsync is required" >&2; exit 1; }
command -v zip   >/dev/null || { echo "error: zip is required"   >&2; exit 1; }

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

rsync -a "$ROOT/" "$STAGE/" \
  --exclude '.git' \
  --exclude 'pyenv' \
  --exclude '.dart_tool' \
  --exclude 'build' \
  --exclude 'ephemeral' \
  --exclude '.gradle' \
  --exclude 'Pods' \
  --exclude 'coverage' \
  --exclude 'dist' \
  --exclude '.vercel' \
  --exclude '.idea' \
  --exclude '.claude' \
  --exclude 'node_modules' \
  --exclude '.next' \
  --exclude 'site/out' \
  --exclude '.env' \
  --exclude '.env.local' \
  --exclude '.env.*.local' \
  --exclude '*.log' \
  --exclude '*.zip' \
  --exclude '*.iml' \
  --exclude 'graphify-out' \
  --exclude '.flutter-plugins-dependencies' \
  --exclude '.DS_Store'

required=(
  README.md HowToSetup.md CLAUDE.md CHANGELOG.md LICENSE-NOTE.md .env.example
  docker-compose.yml docker/Dockerfile
  database/schema.sql database/seed.sql database/README.md
  mobile/README.md pubspec.yaml pubspec.lock
  site/package.json site/package-lock.json
  scripts/prepare_vercel.py
)

missing=0
for f in "${required[@]}"; do
  [[ -e "$STAGE/$f" ]] || { echo "MISSING: $f" >&2; missing=1; }
done
[[ "$missing" -eq 0 ]] || { echo "error: required files missing; not packaging" >&2; exit 1; }

for f in .git pyenv graphify-out site/node_modules site/.next site/out build .dart_tool .vercel; do
  if [[ -e "$STAGE/$f" ]]; then
    echo "error: forbidden path staged: $f" >&2
    exit 1
  fi
done

mkdir -p "$(dirname "$OUT")"
rm -f "$OUT"
(cd "$STAGE" && zip -qr "$OUT" .)

echo "Archive:  $OUT"
echo "Size:     $(du -h "$OUT" | cut -f1)"
echo "SHA-256:  $(sha256sum "$OUT" | cut -d' ' -f1)"
echo
echo "Top level:"
unzip -Z1 "$OUT" | cut -d/ -f1 | sort -u | sed 's/^/  /'
