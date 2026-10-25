#!/usr/bin/env bash
# Compatibility entry point; packaging rules live in the cross-platform script.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec python3 "$ROOT/scripts/make_submission_zip.py" "$@"
