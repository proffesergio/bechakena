#!/usr/bin/env python3
"""Package site/out at / and the compiled Flutter build/web at /demo/."""

import json
from pathlib import Path
import re
import shutil
import tempfile

ROOT = Path(__file__).resolve().parent.parent
SITE = ROOT / "site" / "out"
DEMO = ROOT / "build" / "web"
OUTPUT = ROOT / ".vercel" / "output"
MEDIA = ("pos-en.png", "pos-bn.png", "restaurant.png", "reports.png", "receipt.png", "showcase.webm")
DEMO_REQUIRED = (
    "index.html", "main.dart.js", "flutter.js", "flutter_bootstrap.js",
    "drift_worker.js", "sqlite3.wasm", "assets/assets/fonts/NotoSansBengali.ttf",
    "canvaskit/canvaskit.wasm",
)
PRIVATE_SUFFIXES = {
    ".bak", ".backup", ".csv", ".db", ".dart", ".key", ".log",
    ".p12", ".pem", ".pfx", ".py", ".sql", ".sqlite", ".sqlite3",
    ".ts", ".tsv", ".tsx", ".yaml", ".yml",
}


def require_files(directory, names):
    missing = [name for name in names if not (directory / name).is_file() or not (directory / name).stat().st_size]
    if missing:
        raise ValueError(f"Incomplete {directory.relative_to(ROOT)}: {', '.join(missing)}")


def validate_tree(directory):
    if directory.is_symlink() or not directory.is_dir():
        raise ValueError(f"Expected a real build directory: {directory}")
    for path in directory.rglob("*"):
        relative = path.relative_to(directory)
        if path.is_symlink():
            raise ValueError(f"Public build contains a symlink: {relative}")
        if relative == Path(".last_build_id"):
            continue  # Flutter build bookkeeping, omitted from the upload.
        if any(part.startswith(".") for part in relative.parts) or path.suffix.lower() in PRIVATE_SUFFIXES:
            raise ValueError(f"Unexpected private/source file in public build: {relative}")
        if not path.is_dir() and not path.is_file():
            raise ValueError(f"Unexpected special file in public build: {relative}")


def validate():
    for directory in (SITE, DEMO):
        validate_tree(directory)
    require_files(SITE, ("index.html", "404.html", "fonts/NotoSansBengali.ttf"))
    require_files(SITE, tuple(f"media/{name}" for name in MEDIA))
    require_files(DEMO, DEMO_REQUIRED)
    if not any((SITE / "_next" / "static").rglob("*.js")):
        raise ValueError("Next export has no compiled JavaScript in _next/static")
    if (SITE / "demo").exists():
        raise ValueError("Remove site/public/demo and rebuild: the packager owns /demo/")
    bases = re.findall(r"<base\b[^>]*\bhref\s*=\s*['\"]([^'\"]+)['\"]", (DEMO / "index.html").read_text(), re.I)
    if bases != ["/demo/"]:
        raise ValueError("Flutter must be built with --base-href /demo/")
    for wasm in DEMO.rglob("*.wasm"):
        with wasm.open("rb") as stream:
            if stream.read(4) != bytes.fromhex("0061736d"):
                raise ValueError(f"Invalid WebAssembly module: {wasm.relative_to(DEMO)}")
    for name in MEDIA:
        source = ROOT / "site" / "public" / "media" / name
        exported = SITE / "media" / name
        if source.is_symlink() or not source.is_file() or source.read_bytes() != exported.read_bytes():
            raise ValueError(f"Missing or stale exported capture: {name}; rebuild the site")
        signature = bytes.fromhex("1a45dfa3") if name.endswith(".webm") else bytes.fromhex("89504e470d0a1a0a")
        with exported.open("rb") as stream:
            if stream.read(len(signature)) != signature:
                raise ValueError(f"Invalid capture format: {name}")


def build_config():
    return {
        "version": 3,
        "routes": [
            {"src": "/demo", "status": 308, "headers": {"Location": "/demo/"}},
            {
                "src": "/demo/(.*)",
                "headers": {
                    "Cross-Origin-Opener-Policy": "same-origin",
                    "Cross-Origin-Embedder-Policy": "require-corp",
                    "Cache-Control": "public, max-age=0, must-revalidate",
                },
                "continue": True,
            },
            {
                "src": "/(.*)",
                "headers": {
                    "X-Content-Type-Options": "nosniff",
                    "Referrer-Policy": "strict-origin-when-cross-origin",
                },
                "continue": True,
            },
            {"src": r"/demo/(.*)\.wasm", "headers": {"Content-Type": "application/wasm"}, "continue": True},
            {"src": "/", "dest": "/index.html"},
            {"src": "/demo/", "dest": "/demo/index.html"},
            {"handle": "filesystem"},
            {
                "src": "/demo/(?:tables|products|purchases|inventory|customers|reports|history|settings)/?",
                "dest": "/demo/index.html",
            },
            {"src": "/(.*)", "dest": "/404.html", "status": 404},
        ],
    }


def main():
    try:
        validate()
    except ValueError as error:
        raise SystemExit(str(error)) from error
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    # Complete the new package before replacing the last valid output.
    with tempfile.TemporaryDirectory(prefix="showcase-", dir=OUTPUT.parent) as temporary:
        staged = Path(temporary) / "output"
        static = staged / "static"
        shutil.copytree(SITE, static)
        shutil.copytree(DEMO, static / "demo", ignore=shutil.ignore_patterns(".last_build_id"))
        (staged / "config.json").write_text(json.dumps(build_config(), indent=2) + "\n")
        count = sum(path.is_file() for path in static.rglob("*"))
        if OUTPUT.exists():
            shutil.rmtree(OUTPUT)
        staged.rename(OUTPUT)
    print(f"Packaged {count} public files in {OUTPUT}")


if __name__ == "__main__":
    main()
