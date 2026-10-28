#!/usr/bin/env python3
"""Verify the deployed showcase is the package just built by CI."""

import argparse
from pathlib import Path
import sys
import time
from urllib.error import HTTPError, URLError
from urllib.parse import urljoin
from urllib.request import Request, urlopen


ASSETS = (
    "flutter_bootstrap.js",
    "flutter.js",
    "main.dart.js",
    "drift_worker.js",
    "assets/assets/fonts/NotoSansBengali.ttf",
    "sqlite3.wasm",
    "canvaskit/canvaskit.wasm",
)
WASM_MAGIC = b"\x00asm"


def fetch(base, path, limit=None):
    # Query and request headers ask intermediaries for the newly deployed alias.
    url = urljoin(base, path) + f"?health={int(time.time() * 1000)}"
    request = Request(url, headers={"Cache-Control": "no-cache", "Pragma": "no-cache"})
    with urlopen(request, timeout=10) as response:
        if response.status != 200:
            raise ValueError(f"{path}: HTTP {response.status}")
        body = response.read(limit)
        return body, response.headers


def check(base, expected):
    for path, filename in (("/", "index.html"), ("/demo/", "demo/index.html")):
        body, headers = fetch(base, path)
        if "text/html" not in headers.get("Content-Type", "").lower():
            raise ValueError(f"{path}: expected HTML content type")
        if body != (expected / filename).read_bytes():
            raise ValueError(f"{path}: served HTML does not match this build")
        if path.startswith("/demo/"):
            require_isolation(path, headers)
            if b'<base href="/demo/">' not in body or b'flutter_bootstrap.js' not in body:
                raise ValueError("/demo/: wrong base href or missing Flutter bootstrap")
        elif b"BechaKena" not in body or b"/_next/static/" not in body:
            raise ValueError("/: missing showcase homepage markers")

    for asset in ASSETS:
        path = "/demo/" + asset
        body, headers = fetch(base, path, 4096)
        require_isolation(path, headers)
        if not body:
            raise ValueError(f"{path}: empty asset")
        with (expected / "demo" / asset).open("rb") as local:
            if body != local.read(4096):
                raise ValueError(f"{path}: served asset does not match this build")
        if asset.endswith(".wasm"):
            if body[:4] != WASM_MAGIC:
                raise ValueError(f"{path}: invalid WebAssembly magic")
            if headers.get_content_type() != "application/wasm":
                raise ValueError(f"{path}: expected application/wasm MIME type")


def require_isolation(path, headers):
    if headers.get("Cross-Origin-Opener-Policy", "").lower() != "same-origin":
        raise ValueError(f"{path}: missing same-origin opener policy")
    if headers.get("Cross-Origin-Embedder-Policy", "").lower() != "require-corp":
        raise ValueError(f"{path}: missing require-corp embedder policy")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("url", help="production origin, for example https://bkpos.vercel.app/")
    parser.add_argument("--expected-output", type=Path, default=Path(".vercel/output/static"))
    parser.add_argument("--attempts", type=int, default=12)
    parser.add_argument("--interval", type=float, default=5)
    args = parser.parse_args()
    if not args.url.startswith(("https://", "http://")) or not args.url.endswith("/"):
        parser.error("url must be an HTTP(S) origin ending in /")
    if args.attempts < 1 or args.interval < 0:
        parser.error("attempts must be positive and interval nonnegative")
    for filename in ("index.html", "demo/index.html"):
        if not (args.expected_output / filename).is_file():
            parser.error(f"missing expected package file: {args.expected_output / filename}")
    for attempt in range(1, args.attempts + 1):
        try:
            check(args.url, args.expected_output)
        except (ValueError, HTTPError, URLError, TimeoutError, OSError) as error:
            print(f"Health check {attempt}/{args.attempts}: {error}", file=sys.stderr)
            if attempt == args.attempts:
                raise SystemExit("Deployment failed health check") from error
            time.sleep(args.interval)
        else:
            print(f"Deployment healthy: {args.url} (homepage, demo, Flutter assets)")
            return


if __name__ == "__main__":
    main()
